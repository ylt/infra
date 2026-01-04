# Radarr configuration

resource "radarr_root_folder" "movies" {
  path = "/media/movies"
}

resource "radarr_naming" "naming" {
  rename_movies              = true
  replace_illegal_characters = true
  colon_replacement_format   = "smart"
  movie_folder_format        = "{Movie Title} ({Release Year})"
  standard_movie_format      = "{Movie CleanTitle} {(Release Year)} [{Quality Full}]{[MediaInfo VideoDynamicRangeType]}{[MediaInfo VideoCodec]}{[Mediainfo AudioCodec}{ Mediainfo AudioChannels]}{[MediaInfo AudioLanguages]}{-Release Group}"
}

resource "radarr_notification_emby" "jellyfin" {
  name       = "Jellyfin"
  host       = "jellyfin.media.svc.cluster.local"
  port       = 8096
  api_key    = var.jellyfin_api_key
  use_ssl    = false

  on_download                   = true
  on_upgrade                    = true
  on_movie_added                = true
  on_movie_delete               = true
  on_movie_file_delete          = true
  on_movie_file_delete_for_upgrade = true
  on_rename                     = true
}
