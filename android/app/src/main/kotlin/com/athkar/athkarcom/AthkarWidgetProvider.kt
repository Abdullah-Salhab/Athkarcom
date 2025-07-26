// Create android/app/src/main/kotlin/com/athkar/athkarcom/AthkarWidgetProvider.kt
package com.athkar.athkarcom

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class AthkarWidgetProvider : AppWidgetProvider() {

    companion object {
        const val UPDATE_WIDGET = "es.antonborri.home_widget.action.UPDATE_WIDGET"
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        appWidgetIds.forEach { appWidgetId ->
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        val action = intent.action
        if (action == UPDATE_WIDGET) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(
                android.content.ComponentName(context, AthkarWidgetProvider::class.java)
            )
            appWidgetIds.forEach { appWidgetId ->
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val widgetData = HomeWidgetPlugin.getData(context)

        val views = RemoteViews(context.packageName, R.layout.athkar_widget_layout)

        // Get data from Flutter with safe null handling
        val date = widgetData.getString("date", "اليوم") ?: "اليوم"
        val completedCount = widgetData.getInt("completed_count", 0)
        val totalCount = widgetData.getInt("total_count", 3)
        val percentageStr = widgetData.getString("percentage", "0.0")
        val percentage = percentageStr?.toFloatOrNull() ?: 0.0f
        val streak = widgetData.getInt("streak", 0)
        val completedSections = widgetData.getString("completed_sections", "لم يكتمل أي ذكر بعد") ?: "لم يكتمل أي ذكر بعد"

        // Update views
        views.setTextViewText(R.id.widget_date, date)
        views.setTextViewText(R.id.widget_progress_text, "$completedCount من $totalCount أذكار")
        views.setTextViewText(R.id.widget_percentage, "${percentage.toInt()}%")
        views.setTextViewText(R.id.widget_streak, streak.toString())

        // Update completed sections text
        val sectionsText = if (completedSections.isNotEmpty() && completedSections != "لم يكتمل أي ذكر بعد") {
            completedSections
        } else {
            "لم يكتمل أي ذكر بعد"
        }
        views.setTextViewText(R.id.widget_completed_sections, sectionsText)

        // Update progress bar
        views.setProgressBar(R.id.widget_progress, 100, percentage.toInt(), false)

        // Set click intent to open the app
        val intent = Intent(context, MainActivity::class.java)
        val pendingIntent = android.app.PendingIntent.getActivity(
            context, 0, intent, android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}

// Also create a simple broadcast receiver for updating widgets
class AthkarWidgetReceiver : android.content.BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "com.athkar.athkarcom.UPDATE_WIDGET") {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(
                android.content.ComponentName(context, AthkarWidgetProvider::class.java)
            )

            val widgetIntent = Intent(context, AthkarWidgetProvider::class.java)
            widgetIntent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            widgetIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
            context.sendBroadcast(widgetIntent)
        }
    }
}