# Sonarr configuration

resource "sonarr_root_folder" "tv" {
  path = "/media/tv"
}

resource "sonarr_naming" "naming" {
  rename_episodes             = true
  replace_illegal_characters  = true
  colon_replacement_format    = 4
  standard_episode_format     = "{Series TitleYear} - S{season:00}E{episode:00} - {Episode CleanTitle} [{Quality Full}]{[MediaInfo VideoDynamicRangeType]}{[Mediainfo AudioCodec}{ Mediainfo AudioChannels]}{MediaInfo AudioLanguages}{-Release Group}"
  daily_episode_format        = "{Series TitleYear} - {Air-Date} - {Episode CleanTitle} [{Quality Full}]{[MediaInfo VideoDynamicRangeType]}{[Mediainfo AudioCodec}{ Mediainfo AudioChannels]}{MediaInfo AudioLanguages}{-Release Group}"
  anime_episode_format        = "{Series TitleYear} - S{season:00}E{episode:00} - {absolute:000} - {Episode CleanTitle} [{Quality Full}]{[MediaInfo VideoDynamicRangeType]}[{MediaInfo VideoBitDepth}bit]{[MediaInfo VideoCodec]}{[Mediainfo AudioCodec}{ Mediainfo AudioChannels]}{MediaInfo AudioLanguages}{-Release Group}"
  series_folder_format        = "{Series TitleYear}"
  season_folder_format        = "Season {season}"
  specials_folder_format      = "Specials"
  multi_episode_style         = 5
}

resource "sonarr_notification_emby" "jellyfin" {
  name       = "Jellyfin"
  host       = "jellyfin.media.svc.cluster.local"
  port       = 8096
  api_key    = var.jellyfin_api_key
  use_ssl    = false

  on_download                        = true
  on_upgrade                         = true
  on_import_complete                 = true
  on_rename                          = true
  on_series_add                      = true
  on_series_delete                   = true
  on_episode_file_delete             = true
  on_episode_file_delete_for_upgrade = true
}
