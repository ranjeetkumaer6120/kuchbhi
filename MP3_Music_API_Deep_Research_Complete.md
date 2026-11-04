# MP3 Music APIs and Sources: Research Report

**Research date:** 2 November 2026\
**Scope:** High-quality MP3/audio sources, free access, unofficial APIs,
legal status, technical quality, and practical recommendations.\
**Important boundary:** This report compares legitimate sources and
explains the risks of unauthorized music APIs. It does not provide
piracy API endpoints, scraping recipes, bypass methods, or instructions
for obtaining copyrighted tracks without permission.

## Executive summary

There is no dependable, universally free API that legally provides the
complete commercial music catalog (for example, current Bollywood,
Hollywood, and major-label releases) as unrestricted downloadable MP3
files at original quality.

The available options fall into four groups:

1.  **Open and licensed catalogs**: Internet Archive collections,
    Jamendo, Free Music Archive, and artist-direct sources. These can
    provide legal downloads, but catalog coverage and licensing vary.
2.  **Metadata and discovery APIs**: MusicBrainz, iTunes Search API, and
    similar services help identify tracks and artwork. They are not
    general-purpose MP3 download APIs.
3.  **Streaming services**: Spotify, YouTube Music, Deezer, and similar
    services have their own access rules. Their official APIs generally
    do not grant unrestricted MP3 downloads.
4.  **Unofficial or piracy-oriented endpoints**: These may appear to
    expose popular commercial tracks for free, but can be unauthorized,
    unstable, unsafe, and legally risky. A public endpoint or working
    app does not prove that the operator has distribution rights.

For a personal MP3 library, the safest architecture is to use lawful
downloadable catalogs and user-provided files, while keeping metadata
search separate from audio-file storage.

## What "free MP3 API" can mean

  -----------------------------------------------------------------------
  Type                    What it provides        Does it provide legal
                                                  MP3 downloads?
  ----------------------- ----------------------- -----------------------
  Music metadata API      Track, artist, album,   No, usually metadata
                          identifiers, release    only
                          data                    

  Artwork/search API      Search results and      No
                          cover art               

  Streaming API           Playback inside an      Usually not
                          approved service/app    downloadable MP3 files

  Open music catalog      Tracks under stated     Sometimes, subject to
                          licenses or             each track's terms
                          public-domain status    

  Unofficial aggregator   May expose links or     Rights are often
                          streams from third      unclear; do not assume
                          parties                 lawful

  User-owned library      Files the user owns or  Yes, within the
                          has permission to use   relevant rights
  -----------------------------------------------------------------------

## Legitimate free and low-cost sources

The following are useful starting points. "Free" does not mean every
track is free for every use. Check the license and download terms for
each recording.

### 1. Internet Archive

-   **Best for:** Public-domain recordings, historical audio,
    community-uploaded collections, and some openly licensed music.
-   **Audio formats:** Vary by item; MP3 is available for many
    recordings, but not guaranteed.
-   **API/access:** Archive.org provides public metadata/search and item
    access mechanisms.
-   **Quality:** Highly variable. Some uploads are high bitrate or
    lossless originals; others are low-bitrate encodes or transfers from
    old media.
-   **Rights caution:** The uploader's claim is not a substitute for
    checking copyright status and item-level rights information.
-   **Recommendation:** Useful for lawful discovery and downloads when
    the item's rights and license are clear.

Official resources: - https://archive.org/ -
https://archive.org/developers/

### 2. Jamendo

-   **Best for:** Independent music distributed under Creative Commons
    or other Jamendo terms.
-   **Audio formats/quality:** Depends on the service and track; verify
    current download/API terms.
-   **API/access:** Jamendo has offered developer access for catalog
    search and playback-related use, subject to its current terms and
    client registration.
-   **Quality:** Suitable for independent music discovery; not a
    replacement for a major-label catalog.
-   **Rights caution:** Creative Commons licenses differ. Attribution,
    non-commercial, and share-alike restrictions may apply.
-   **Recommendation:** One of the better options when a project needs a
    searchable independent-music catalog with explicit licensing.

Official resources: - https://www.jamendo.com/ -
https://developer.jamendo.com/

### 3. Free Music Archive (FMA)

-   **Best for:** Independent and openly licensed music.
-   **Audio formats/quality:** Track-specific; inspect the actual file
    and license.
-   **API/access:** Historically offered APIs and downloadable catalog
    access; verify present-day availability and terms before building
    against it.
-   **Quality:** Mixed, depending on source upload.
-   **Rights caution:** Do not assume every track is public domain or
    commercially reusable.
-   **Recommendation:** A useful catalog for experimentation, provided
    current access and each track's license are confirmed.

Official resource: - https://freemusicarchive.org/

### 4. Artist and label direct downloads

-   **Best for:** Music where the artist or label explicitly provides
    downloadable files.
-   **Audio formats/quality:** Sometimes MP3, FLAC, or WAV; the artist
    controls the offering.
-   **API/access:** Usually no universal API. Some platforms provide
    feeds, embeds, or download links.
-   **Quality:** Can be excellent when the original file is offered.
-   **Rights caution:** A download button grants only the permissions
    stated by the artist/platform.
-   **Recommendation:** Strong option for a curated collection and
    direct permission.

### 5. Public-domain and CC0 collections

-   **Best for:** Works whose copyright has expired or whose rights
    holders have dedicated them to the public domain.
-   **Audio formats/quality:** Varies.
-   **API/access:** Depends on the archive or institution.
-   **Rights caution:** A composition and a particular sound recording
    can have different copyright status. Confirm both where relevant.
-   **Recommendation:** Good for a low-risk free catalog, but it will
    not cover most current commercial releases.

## Metadata and discovery APIs (not MP3 download APIs)

### MusicBrainz

-   **Purpose:** Open music metadata database: artists, releases,
    recordings, labels, and identifiers.
-   **Audio downloads:** Not a general MP3 hosting or download service.
-   **Use case:** Resolve artist/album/recording metadata and normalize
    a personal music library.
-   **Official documentation:**
    https://musicbrainz.org/doc/MusicBrainz_API

### Apple iTunes Search API

-   **Purpose:** Search Apple's catalog and retrieve metadata and
    preview-related fields where available.
-   **Audio downloads:** Preview snippets are not equivalent to
    permission to download full tracks.
-   **Use case:** Search, metadata, artwork, and limited preview
    workflows, subject to Apple terms.
-   **Official documentation:**
    https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/iTuneSearchAPI/

### ListenBrainz

-   **Purpose:** Listening history, recommendations, and music discovery
    built around user-authorized listening data.
-   **Audio downloads:** Not a general MP3 download host.
-   **Use case:** Personal listening history and discovery.
-   **Official documentation:** https://listenbrainz.org/

## Commercial streaming APIs and why they are different

  -----------------------------------------------------------------------
  Service                 Typical developer role  Unrestricted MP3
                                                  download API?
  ----------------------- ----------------------- -----------------------
  Spotify                 Catalog metadata and    No
                          approved playback       
                          integrations            

  YouTube Data API        Search and manage       No general MP3
                          YouTube resources       extraction permission
                          within API rules        

  Deezer                  Catalog and service     No general unrestricted
                          integrations, subject   MP3 download permission
                          to current access rules 

  SoundCloud              Track discovery and     Not a general-purpose
                          approved                MP3 download API
                          embeds/streaming,       
                          subject to rights and   
                          API access              
  -----------------------------------------------------------------------

API availability, access tiers, and terms can change. Confirm current
official documentation before implementation. Do not treat stream URLs,
previews, cached media, or app-internal endpoints as downloadable-file
licenses.

## Unofficial APIs: technical and legal assessment

Unofficial endpoints are often reverse-engineered interfaces,
third-party aggregators, proxy services, or wrappers around another
platform. They may stop working when the upstream service changes.

### Common risks

-   **Copyright and distribution rights:** An API operator may not have
    permission to distribute the recording. Free access does not
    establish authorization.
-   **Terms-of-service violations:** Automated extraction, scraping, or
    use of private app endpoints may violate platform terms even when
    the underlying track can be streamed in an official app.
-   **Security:** Untrusted endpoints can return misleading links,
    malicious redirects, executable files, or unexpected payloads.
-   **Privacy:** Some services log IP addresses, search queries, device
    identifiers, or tokens.
-   **Reliability:** Endpoints may disappear, change response formats,
    impose hidden rate limits, or be blocked without notice.
-   **Quality claims:** A response labelled "320 kbps" may be transcoded
    from a lower-quality source. Bitrate alone does not prove source
    quality.
-   **Operational risk:** Your app may break suddenly, and you may have
    no support or service-level agreement.

### What this report deliberately does not provide

It does not list piracy-oriented API hostnames, reverse-engineered
private endpoints, scraping scripts, extraction commands, or methods for
bypassing download restrictions. Those details would directly enable
unauthorized acquisition of copyrighted music.

## Understanding MP3 quality

  -----------------------------------------------------------------------
  MP3 bitrate             General listening       Notes
                          assessment              
  ----------------------- ----------------------- -----------------------
  96 kbps                 Low                     Smaller files; audible
                                                  compression on complex
                                                  material

  128 kbps                Basic                   Often acceptable for
                                                  casual listening, but
                                                  compression is
                                                  noticeable

  192 kbps                Good                    A reasonable compromise
                                                  for many listeners

  256 kbps                Very good               High-quality lossy
                                                  encoding

  320 kbps                High MP3 bitrate        Maximum common CBR MP3
                                                  bitrate; still lossy
  -----------------------------------------------------------------------

Important: - 320 kbps does not automatically mean studio-original
quality. - Re-encoding a 128 kbps source to 320 kbps does not restore
lost detail. - VBR files may report varying bitrates and can still sound
excellent. - FLAC/WAV are preferable when preserving a lossless source
matters, but they are larger. - Evaluate the actual file, source
provenance, codec, sample rate, and clipping/noise, not only a filename
or API label.

## Recommended architecture for a personal MP3 application

### Data flow

1.  Search a metadata provider such as MusicBrainz or Apple Search for
    artist, album, and track information.
2.  Search only catalogs that explicitly provide downloadable files
    under clear terms.
3.  Store the track's source URL, license, attribution text, and rights
    evidence alongside metadata.
4.  Download only where the catalog or rights holder explicitly permits
    it.
5.  Store the user's own imported audio files locally or in private
    object storage.
6.  Generate tags and artwork from metadata, respecting provider terms.
7.  Provide a source/rights field in the UI so users can see where each
    file came from.

### Suggested database fields

  Field                  Purpose
  ---------------------- ------------------------------------
  `track_id`             Internal identifier
  `title`                Track title
  `artist`               Artist name
  `album`                Album name
  `duration_ms`          Duration
  `codec`                MP3, FLAC, WAV, etc.
  `bitrate_kbps`         Measured bitrate
  `sample_rate_hz`       Measured sample rate
  `file_path`            Local/private storage path
  `source_name`          Archive, artist, user import, etc.
  `source_url`           Original source page
  `license`              Exact license identifier/text
  `attribution`          Required credit
  `rights_verified_at`   Verification date
  `checksum_sha256`      File integrity check

### Java/Spring Boot implementation outline

-   `MusicMetadataService`: query metadata providers.
-   `OpenCatalogService`: integrate only with documented, permitted
    download catalogs.
-   `UserLibraryService`: import and index user-provided files.
-   `AudioMetadataService`: inspect codec, bitrate, duration, and tags.
-   `RightsPolicyService`: reject downloads where license/permission is
    missing or incompatible.
-   `StorageService`: store authorized files in local/private object
    storage.
-   `MusicController`: expose search, library, and playback endpoints
    for the user's own authorized files.

Do not proxy or rehost third-party audio unless the source's terms
explicitly permit it.

## Comparison and practical recommendation

  --------------------------------------------------------------------------------------------------------
  Source                   Free access         MP3 availability       Commercial      Best role
                                                                      mainstream      
                                                                      catalog         
  ------------------------ ------------------- ---------------------- --------------- --------------------
  Internet Archive         Often               Item-dependent         No              Public-domain/open
                                                                                      archives

  Jamendo                  Limited/free tiers  Track/plan-dependent   No              Independent licensed
                           or terms-dependent                                         music

  Free Music Archive       Catalog-dependent   Track-dependent        No              Independent/open
                                                                                      music

  Artist direct            Artist-dependent    Often possible         Only            Direct authorized
                                                                      participating   downloads
                                                                      artists         

  MusicBrainz              Yes, subject to API No                     Metadata        Metadata
                           policy                                     coverage, not   
                                                                      files           

  Apple Search API         Search access       Previews/metadata, not Broad catalog   Discovery
                           subject to terms    full MP3 downloads     metadata        

  Spotify/Deezer/YouTube   Service/API         No unrestricted MP3    Broad streaming Official
                           dependent           download               catalogs        playback/discovery
  --------------------------------------------------------------------------------------------------------

### Final recommendation

If the goal is a **personal MP3 player/library**, use: - User-imported
files that the user has lawfully obtained. - Internet Archive items with
clear public-domain or license status. - Jamendo or FMA tracks whose
specific license permits the intended use. - MusicBrainz for metadata
enrichment.

If the goal is a **commercial music app**, do not build the product
around unofficial download endpoints. Obtain distribution rights or use
an authorized music licensing/streaming provider. A personal-use app
does not automatically make unauthorized downloading or redistribution
lawful.

## Pre-launch checklist

-   [ ] Confirm the recording's rights, not just the composition's
    rights.
-   [ ] Read the exact license for each track.
-   [ ] Confirm whether downloading, caching, and offline playback are
    allowed.
-   [ ] Confirm whether the license permits commercial use if the app
    may later be monetized.
-   [ ] Preserve required attribution.
-   [ ] Respect API rate limits and terms.
-   [ ] Verify audio properties from the downloaded file itself.
-   [ ] Keep a source URL and rights-verification record.
-   [ ] Provide a takedown/contact process if hosting user or
    third-party uploads.

## Sources and further reading

-   Internet Archive Developers: https://archive.org/developers/
-   Jamendo Developer Portal: https://developer.jamendo.com/
-   Free Music Archive: https://freemusicarchive.org/
-   MusicBrainz API: https://musicbrainz.org/doc/MusicBrainz_API
-   Apple iTunes Search API:
    https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/iTuneSearchAPI/
-   ListenBrainz: https://listenbrainz.org/
-   Spotify Developer Policy: https://developer.spotify.com/policy
-   YouTube API Services Terms:
    https://developers.google.com/youtube/terms/api-services-terms-of-service
-   SoundCloud API: https://developers.soundcloud.com/docs/api/guide
-   Creative Commons licenses:
    https://creativecommons.org/share-your-work/cclicenses/

**Verification note:** API access, pricing, geographic availability, and
platform policies change. Treat the official documentation linked above
as authoritative and re-check it before development. This report is a
technical comparison, not legal advice.


---

## Additional verified findings (checked 2 November 2026)

### FreeToUse API: a notable direct-download candidate

The Free To Use public API advertises search, streaming, and direct music downloads without an API key or account. It states that tracks are covered by its own Free To Use License, with free usage subject to conditions and commercial use requiring a paid license. This makes it a relevant candidate for a personal MP3 app, but it is not an unrestricted mainstream-music catalog. Review the exact license and track-level conditions before downloading or storing anything.

- API overview: https://freetouse.com/api
- License: https://freetouse.com/license
- OpenAPI specification: https://api.freetouse.com/v3/openapi.json

### Jamendo: API access and download permission are separate

Jamendo's official API requires a developer `client_id`. Its track response includes `audiodownload_allowed`; the API documentation says this field indicates whether an application may offer the download option for that track. The application must check this value rather than assume all searchable tracks can be downloaded.

- Track API: https://developer.jamendo.com/v3.0/tracks
- Authentication and client ID: https://developer.jamendo.com/v3.0/authentication

### Free Music Archive: legacy API is shut down

FMA's own developer page says its API was shut down due to server load. It also disallows hotlinking/playing FMA-hosted audio directly from its servers and says app developers may host music on their own server only while following the applicable Creative Commons license conditions. It also prohibits forwarding user search queries to its search engine and scraping returned HTML without explicit approval. Do not design a new app around the old FMA API.

- FMA app developer guidance: https://freemusicarchive.org/app-developers

### Internet Archive: search and metadata are available, rights still need item-level review

Internet Archive provides search and metadata APIs for discovering items. Its metadata search is useful for finding candidate audio items, but an item being downloadable does not itself prove that its recording is public domain or licensed for the intended use. Verify the item's rights statement and provenance before importing it.

- Developer portal: https://archive.org/developers/
- Search guide: https://archivesupport.zendesk.com/hc/en-us/articles/360018359991-Search-A-Basic-Guide

### Apple previews are promotional assets, not a full-track source

Apple's Search API documentation describes preview clips as promotional content for store content and says they must be used to promote that store content, with the relevant store badge nearby. A preview URL should not be treated as permission to build an MP3 download library.

- Apple Search API: https://performance-partners.apple.com/search-api

### YouTube and SoundCloud restrictions

YouTube's developer policy expressly disallows API clients from enabling users to download or separate audio tracks from YouTube content, and disallows downloading/caching audiovisual content without prior written approval. YouTube Help also says its app does not provide audio/music/MP3 file downloads.

SoundCloud's API terms prohibit file-save functionality and persistent storage/offline access to User Content, apart from narrowly limited session caching. Do not assume a track's presence on SoundCloud or an accessible stream URL authorizes an MP3 download.

- YouTube developer policy guide: https://developers.google.com/youtube/terms/developer-policies-guide
- YouTube API policy: https://developers.google.com/youtube/terms/developer-policies
- YouTube Help: https://support.google.com/youtube/answer/7381437
- SoundCloud API terms: https://developers.soundcloud.com/docs/api/terms-of-use

### Spotify is not a general MP3 download provider

Spotify's developer policy restricts streaming of music sound recordings through the platform to Premium subscribers, with previews/widgets available only where supported. The developer platform is not a permission to export full tracks as MP3 files.

- Spotify Developer Policy: https://developer.spotify.com/policy
- Spotify Developer Terms: https://developer.spotify.com/terms

### MusicBrainz: useful, but metadata only

MusicBrainz states that its API is free for non-commercial use, requires a meaningful User-Agent, and limits applications to one request per second. It provides metadata, not hosted MP3 downloads.

- API: https://musicbrainz.org/doc/MusicBrainz_API
- Rate limiting: https://musicbrainz.org/doc/MusicBrainz_API/Rate_Limiting

## Updated shortlist for this personal MP3-only app

| Priority | Source | What to use it for | Key point |
|---|---|---|---|
| 1 | User's own MP3 files | Main library and playback | Most predictable source when files were lawfully obtained |
| 2 | FreeToUse API | Search and download tracks in its catalog | Review its license; not mainstream commercial catalog |
| 3 | Jamendo API | Independent music search and permitted downloads | Require `audiodownload_allowed = true` and retain license/attribution |
| 4 | Internet Archive | Public-domain/openly licensed archive audio | Verify rights per item |
| 5 | MusicBrainz | Metadata enrichment and tagging | Does not provide audio files |
| Avoid as a download source | FMA legacy API, YouTube extraction, SoundCloud unofficial endpoints, Spotify private endpoints | Not a dependable authorized MP3 download path | API shutdown, explicit policy restrictions, or unclear rights |

**Bottom line:** There are several useful free sources, but no verified free API that legally supplies an unlimited catalog of current commercial songs as downloadable high-quality MP3s. For the user's personal MP3-only app, combine the user's own files with clearly licensed open catalogs, and use metadata APIs only for metadata. Avoid relying on unofficial/private endpoints for copyrighted commercial tracks.


---

# Live web research verification appendix

**Live research performed:** 2 November 2026  
**Method:** Official developer documentation, API terms, licensing pages, and service policy pages were searched and checked. This appendix supersedes any earlier unverified generalization in the report.

## Verified API and license findings

### Free To Use public API

The official API page states that it supports searching, discovering, streaming, and downloading tracks, with no API key or account required. It says API music is governed by the Free To Use License. However, the license is crucial: the free license allows non-premium assets for qualifying user-generated social content with attribution, and expressly excludes use in commercial content and digital products. The license also prohibits redistribution, sublicensing, and making assets available to third parties.

**Conclusion:** The API is real and free to test, but do not assume its free tier permits building and distributing a standalone MP3 player/catalog app. Obtain a license that explicitly covers the intended digital product and audio delivery model.

Sources:
- API: https://freetouse.com/api
- Full license: https://freetouse.com/license
- Usage policy: https://freetouse.com/usage-policy
- FAQ/pricing: https://freetouse.com/faq

### Jamendo API

Jamendo requires a developer account and `client_id` for API requests. Its track API returns `audiodownload_allowed`; Jamendo says developers must use this field to determine whether their app may offer a download for that track. Its file endpoint redirects to the requested file and can return 404 when download is not permitted.

**Conclusion:** A strong candidate for an independent-music catalog. Implement a per-track permission check, preserve the applicable license/attribution, and review Jamendo's current API terms for the app's use case.

Sources:
- Authentication/client ID: https://developer.jamendo.com/v3.0/authentication
- Tracks: https://developer.jamendo.com/v3.0/tracks
- File endpoint: https://developer.jamendo.com/v3.0/tracks/file

### Free Music Archive (FMA)

FMA's app developer page confirms that its former API was shut down due to server load. It disallows direct hotlinking/playing of FMA-hosted music from its servers. It says app developers may use FMA music hosted on their own server only while complying with the applicable Creative Commons license conditions. It also disallows forwarding user searches to its search engine and scraping returned HTML without explicit approval.

**Conclusion:** Do not build a new app against the old FMA API or scrape its website. Contact FMA for an approved integration approach before using its catalog.

Source:
- https://freemusicarchive.org/app-developers

### Internet Archive

Internet Archive search supports advanced queries and machine-readable outputs such as JSON, XML, CSV, and RSS. This is useful for discovering audio items, but the existence of a downloadable file is not proof that the recording is public domain or licensed for the intended use.

**Conclusion:** Use it as a discovery source, then verify item-level rights, uploader/provenance, recording rights, and download terms before importing.

Sources:
- https://archive.org/developers/
- https://archivesupport.zendesk.com/hc/en-us/articles/360018359991-Search-A-Basic-Guide

### MusicBrainz

MusicBrainz provides metadata, not MP3 hosting. Its API FAQ says non-commercial API use is free, no API key is currently required, and clients must use a meaningful User-Agent. The API policy requires no more than one request per second per client application.

**Conclusion:** Recommended for metadata enrichment, not audio acquisition.

Sources:
- https://musicbrainz.org/doc/MusicBrainz_API
- https://musicbrainz.org/doc/MusicBrainz_API/Rate_Limiting

### Apple Search API

Apple's Search API provides catalog search metadata and preview-related information. Preview clips are promotional assets for the relevant store content and are not a general full-track MP3 download entitlement.

**Conclusion:** Use for discovery/metadata and permitted preview use only, not as a full-track MP3 source.

Source:
- https://performance-partners.apple.com/search-api

### Spotify

Spotify's developer policy says streaming of music sound recordings through the Spotify Platform is only permitted for Premium subscribers, with widgets and audio preview clips available only where supported.

**Conclusion:** Not a general-purpose MP3 export/download API.

Sources:
- https://developer.spotify.com/policy
- https://developer.spotify.com/terms

### YouTube

YouTube's developer policy guide explicitly says API clients must not offer users the ability to download or separate audio tracks, including offering MP3 files from audio that appeared in YouTube videos. It also prohibits downloading videos for offline play outside the YouTube Premium experience.

**Conclusion:** Do not use YouTube API or unofficial extraction wrappers as the MP3 acquisition backend.

Sources:
- https://developers.google.com/youtube/terms/developer-policies-guide
- https://developers.google.com/youtube/terms/api-services-terms-of-service

### SoundCloud

SoundCloud API terms say apps must not include file-save functionality or persistently store User Content. They prohibit offline access and permanent or temporary downloads for offline listening, except narrowly scoped session caching needed to operate the app.

**Conclusion:** Do not treat SoundCloud API access or a stream URL as permission to build a permanent MP3 library.

Source:
- https://developers.soundcloud.com/docs/api/terms-of-use

## Updated source assessment

| Source | Search/metadata | Stream/preview | Direct file download | Key restriction |
|---|---|---|---|---|
| Free To Use | Yes | Yes | Yes, per its API | Free license excludes digital products and redistribution; obtain appropriate license |
| Jamendo | Yes | Yes | Yes, only when permitted | Check `audiodownload_allowed` per track and license |
| Internet Archive | Yes | Item-dependent | Item-dependent | Verify rights per item |
| Free Music Archive | No current public API | Do not hotlink | License-dependent, approved use only | Legacy API shut down; no unauthorized scraping |
| MusicBrainz | Yes | No | No | Metadata service; non-commercial free use and rate limit |
| Apple Search | Yes | Preview clips | No general full-track right | Preview use is promotional and terms-limited |
| Spotify | Yes | Approved playback/preview | No unrestricted MP3 | Premium and platform policy constraints |
| YouTube | Video search | Official player | No MP3 extraction | Explicit prohibition on audio separation/download |
| SoundCloud | Yes | Approved streaming | No persistent/offline downloads via API | No file-save/persistent storage |

## Unofficial / unauthorized API risk review

A public GitHub repository, reverse-engineered mobile endpoint, or third-party wrapper does not establish that its operator has rights to distribute the music. Such projects can be useful to study API design, but should not be treated as authorized catalogs unless they document the rights chain and permitted use.

Risk categories to assess:
- Copyright infringement or unauthorized communication/distribution of recordings.
- Breach of upstream platform terms, API policies, or access controls.
- Unstable private endpoints and sudden service shutdowns.
- Malware, deceptive redirects, credential theft, and unsafe downloaded files.
- Privacy exposure through third-party proxies and logging.
- False bitrate labels and transcoded low-quality source audio.
- Lack of support, takedown process, or contractual rights.

This report intentionally does not provide piracy endpoint lists, private endpoint extraction instructions, or bypass scripts.

## Final recommendation for a personal MP3-only player

1. Make user-imported, lawfully obtained MP3 files the primary library.
2. Integrate Jamendo only for tracks whose API response explicitly permits downloads and whose license fits the app.
3. Use Internet Archive only after item-level rights checks.
4. Use MusicBrainz for metadata, not files.
5. Treat Free To Use as a licensing discussion before integrating into a distributable player; its free license is not a blanket app-distribution license.
6. Do not depend on YouTube/SoundCloud/Spotify extraction or reverse-engineered private endpoints.

**Research limitation:** This is a web-based technical and policy review, not a legal opinion. API availability, pricing, licenses, and regional access may change. Confirm current terms with each provider before release.
