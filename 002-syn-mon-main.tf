#Bucket
resource "google_storage_bucket" "hall-monitor" {
   name = "synmod-storage"
   location = "EU"
   uniform_bucket_level_access = true
}

#Bucket-Object
resource "google_storage_bucket_object" "object-1" {
   name = "example-function.zip"
   bucket = google_storage_bucket.hall-monitor.name
   source = "funky.zip"
}
#>>>

#Functions have to be in a zip file in order to execute

#Cloud function
resource "google_cloudfunctions2_function" "funky-1" {
   name = "we-got-the-funk"
   location = "europe-central2"

   build_config {
      runtime = "nodejs20"
      entry_point = "SyntheticFunction"
      source {
            storage_source {
               bucket = google_storage_bucket.hall-monitor.name
               object = google_storage_bucket_object.object-1.name
            }
      }
   }

   service_config {
      max_instance_count = 8
      min_instance_count = 1
      available_memory = "256Mi"
      timeout_seconds  = 60
   }
}
#>>>
/*
#Syn-mon
resource "google_monitoring_uptime_check_config" "https" {
  display_name = "android-3276"
  timeout = "60s"

  http_check {
    path = "/"
    port = "443"
    use_ssl = true
    validate_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = "pooper-scooper"
      host = "10.186.0.8"
    }
  }

  content_matchers {
    content = "example"
    matcher = "MATCHES_JSON_PATH"
    json_path_matcher {
      json_path = "$.path"
      json_matcher = "REGEX_MATCH"
    }
  }
  
#Let's see if this works; nope, Can't have both, I'll just comment it out for now.
   synthetic_monitor {
      cloud_function_v2 {
            name = google_cloudfunctions2_function.funky-1.id
      }
   }

}
#>>>
*/

resource "google_monitoring_uptime_check_config" "https" {
   display_name = "android-3276"
   timeout = "30s"

   synthetic_monitor {
      cloud_function_v2 {
            name = google_cloudfunctions2_function.funky-1.id
      }
   }
}

# Notification Channel
resource "google_monitoring_notification_channel" "basic" {
  display_name = "Test Notification Channel"
  type         = "email"
  labels = {
    email_address = "premiumforges32@gmail.com"
  }
  force_delete = false
}
#>>>

#2
resource "google_monitoring_notification_channel" "GCHAT-OUTLINE" {
  display_name = "whatever"
  enabled      = true

  labels = {
    space = "spaces/AAAAJ6qPVn4"
  }
  type    = "google_chat"
}
#>>>

# Alert Policy
resource "google_monitoring_alert_policy" "alert_policy" {
  display_name = "Uptime Check Alert Policy"
  combiner     = "OR"
  enabled = true
  notification_channels = [
    google_monitoring_notification_channel.basic.id,
    google_monitoring_notification_channel.GCHAT-OUTLINE.id
  ]

  conditions {
    display_name = "Uptime Check Condition"
    condition_threshold {
      filter          = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" AND metric.label.check_id=\"android-3276-d6DKSiVxshE\" AND resource.type=\"cloud_run_revision\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0
           /* I Literally have no idea what this is, But The AI Recommended I remove this to clear my error messages.
            aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_NONE"
      }
      */
    }
  }
  alert_strategy {
    auto_close = "3600s"
  }
    depends_on = [
    google_monitoring_uptime_check_config.https
  ]
}