package com.athkar.athkarcom

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class PrayerWidgetProvider : AppWidgetProvider() {

    companion object {
        const val UPDATE_PRAYER_WIDGET = "es.antonborri.home_widget.action.UPDATE_WIDGET"
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        appWidgetIds.forEach { appWidgetId ->
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        val action = intent.action
        if (action == UPDATE_PRAYER_WIDGET || action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(
                android.content.ComponentName(context, PrayerWidgetProvider::class.java)
            )
            appWidgetIds.forEach { appWidgetId ->
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val widgetData = HomeWidgetPlugin.getData(context)

        val views = RemoteViews(context.packageName, R.layout.prayer_widget_layout)

        // Get data from Flutter with safe default values
        val date = widgetData.getString("prayer_date", "اليوم") ?: "اليوم"
        val city = widgetData.getString("prayer_city", "موقعي") ?: "موقعي"
        val nextPrayerName = widgetData.getString("next_prayer_name", "الفجر") ?: "الفجر"
        val nextPrayerTime = widgetData.getString("next_prayer_time", "--:--") ?: "--:--"

        val fajr = widgetData.getString("fajr", "--:--") ?: "--:--"
        val sunrise = widgetData.getString("sunrise", "--:--") ?: "--:--"
        val dhuhr = widgetData.getString("dhuhr", "--:--") ?: "--:--"
        val asr = widgetData.getString("asr", "--:--") ?: "--:--"
        val maghrib = widgetData.getString("maghrib", "--:--") ?: "--:--"
        val isha = widgetData.getString("isha", "--:--") ?: "--:--"

        // Update UI components
        views.setTextViewText(R.id.widget_prayer_date, date)
        views.setTextViewText(R.id.widget_prayer_city, city)
        views.setTextViewText(R.id.widget_next_prayer_name, nextPrayerName)
        views.setTextViewText(R.id.widget_next_prayer_time, nextPrayerTime)

        views.setTextViewText(R.id.widget_fajr_time, fajr)
        views.setTextViewText(R.id.widget_sunrise_time, sunrise)
        views.setTextViewText(R.id.widget_dhuhr_time, dhuhr)
        views.setTextViewText(R.id.widget_asr_time, asr)
        views.setTextViewText(R.id.widget_maghrib_time, maghrib)
        views.setTextViewText(R.id.widget_isha_time, isha)

        // Set click intent to open the app
        val intent = Intent(context, MainActivity::class.java)
        val pendingIntent = android.app.PendingIntent.getActivity(
            context, 1, intent, android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}

// Broadcast receiver for updating the prayer widget
class PrayerWidgetReceiver : android.content.BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "com.athkar.athkarcom.UPDATE_PRAYER_WIDGET") {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(
                android.content.ComponentName(context, PrayerWidgetProvider::class.java)
            )

            val widgetIntent = Intent(context, PrayerWidgetProvider::class.java)
            widgetIntent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            widgetIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
            context.sendBroadcast(widgetIntent)
        }
    }
}
