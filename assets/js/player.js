/**
 * kuchbhi — Interactive Apple Music Web Player Demo & Live Lyrics Engine
 */

document.addEventListener('DOMContentLoaded', () => {
  // Demo Songs List
  const demoPlaylist = [
    {
      title: "Kesariya",
      artist: "Arijit Singh, Pritam",
      album: "Brahmastra (Master HD)",
      duration: 268,
      artwork: "https://c.saavncdn.com/191/Kesariya-From-Brahmastra-Hindi-2022-20220717092820-500x500.jpg",
      lyrics: [
        { time: 0, text: "🎵 [Acoustic Guitar Strumming]" },
        { time: 9.4, text: "मुझको इतना बताए कोई" },
        { time: 19.0, text: "कैसे तुझसे दिल ना लगाए कोई?" },
        { time: 29.9, text: "रब्बा ने तुझको बनाने में" },
        { time: 34.2, text: "कर दी हैं हुस्न की ख़ाली तिजोरियाँ" },
        { time: 40.3, text: "काजल की सियाही से लिखी हैं तूने" },
        { time: 45.3, text: "जाने कितनों की लव-स्टोरियाँ" },
        { time: 49.3, text: "केसरिया तेरा इश्क़ है, पिया" },
        { time: 54.2, text: "रंग जाऊँ जो मैं हाथ लगाऊँ" },
        { time: 58.3, text: "दिन बीते सारा तेरी फ़िक्र में" },
        { time: 63.0, text: "रैन सारी तेरी ख़ैर मनाऊँ" },
        { time: 69.9, text: "केसरिया तेरा इश्क़ है, पिया" },
        { time: 74.7, text: "रंग जाऊँ जो मैं हाथ लगाऊँ" }
      ]
    },
    {
      title: "Chaleya",
      artist: "Arijit Singh, Shilpa Rao",
      album: "Jawan (Master HD)",
      duration: 200,
      artwork: "https://c.saavncdn.com/026/Chaleya-From-Jawan-Hindi-2023-20230814114323-500x500.jpg",
      lyrics: [
        { time: 0, text: "🎵 [Dance Electro Beat]" },
        { time: 8.0, text: "इश्क़ में दिल बना है, इश्क़ में दिल फ़ना है" },
        { time: 15.5, text: "हँसा है, कभी रोया है" },
        { time: 22.0, text: "तेरी आँखों के जादू ने ऐसा छुआ" },
        { time: 28.5, text: "चलेया, चलेया तेरी ओर चलेया" },
        { time: 35.0, text: "तू मेरा हमदम, तू ही सहारा" }
      ]
    },
    {
      title: "Midnight Chill Beats",
      artist: "Lo-Fi Beats • Relax",
      album: "Chill Out (320k)",
      duration: 180,
      artwork: "https://images.unsplash.com/photo-1518609878373-06d740f60d8b?w=500&auto=format&fit=crop&q=80",
      lyrics: [
        { time: 0, text: "🎵 [Smooth Vinyl Crackle & Soft Piano]" },
        { time: 12.0, text: "☕ Pure Instrumental Lo-Fi Study Beats" },
        { time: 30.0, text: "🌙 Relax, Code, and Vibe" },
        { time: 55.0, text: "🎧 Zero Ads • Continuous Playback" }
      ]
    }
  ];

  let currentSongIndex = 0;
  let isPlaying = false;
  let currentTime = 0;
  let playInterval = null;

  // DOM Elements
  const playBtn = document.getElementById('play-btn');
  const prevBtn = document.getElementById('prev-btn');
  const nextBtn = document.getElementById('next-btn');
  const songTitle = document.getElementById('player-title');
  const songArtist = document.getElementById('player-artist');
  const songArtwork = document.getElementById('player-artwork');
  const lyricsContainer = document.getElementById('lyrics-container');
  const progressFill = document.getElementById('progress-fill');
  const progressTrack = document.getElementById('progress-track');
  const timeCurrent = document.getElementById('time-current');
  const timeTotal = document.getElementById('time-total');
  const favoriteBtn = document.getElementById('player-fav-btn');
  const soundwave = document.getElementById('player-soundwave');
  const songPills = document.querySelectorAll('.demo-song-pill');

  function formatTime(seconds) {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }

  function renderLyrics(song) {
    lyricsContainer.innerHTML = '';
    song.lyrics.forEach((line, idx) => {
      const row = document.createElement('div');
      row.className = 'lyric-row';
      row.id = `lyric-${idx}`;
      row.textContent = line.text;
      row.addEventListener('click', () => {
        currentTime = line.time;
        updateProgress();
        updateActiveLyric();
      });
      lyricsContainer.appendChild(row);
    });
  }

  function loadSong(index) {
    currentSongIndex = index;
    const song = demoPlaylist[currentSongIndex];
    songTitle.textContent = song.title;
    songArtist.textContent = song.artist;
    songArtwork.src = song.artwork;
    timeTotal.textContent = formatTime(song.duration);
    currentTime = 0;
    updateProgress();
    renderLyrics(song);
    updateActiveLyric();

    // Update song pills
    songPills.forEach((pill, idx) => {
      if (idx === index) pill.classList.add('active');
      else pill.classList.remove('active');
    });
  }

  function updateProgress() {
    const song = demoPlaylist[currentSongIndex];
    const percent = Math.min(100, (currentTime / song.duration) * 100);
    progressFill.style.width = `${percent}%`;
    timeCurrent.textContent = formatTime(currentTime);
  }

  function updateActiveLyric() {
    const song = demoPlaylist[currentSongIndex];
    let activeIdx = 0;

    for (let i = 0; i < song.lyrics.length; i++) {
      if (currentTime >= song.lyrics[i].time) {
        activeIdx = i;
      } else {
        break;
      }
    }

    const rows = lyricsContainer.querySelectorAll('.lyric-row');
    rows.forEach((r, idx) => {
      if (idx === activeIdx) {
        r.classList.add('active');
        // Only auto-scroll the lyrics box internally while playing (never scroll the main window)
        if (isPlaying) {
          const containerHeight = lyricsContainer.clientHeight;
          const rowTop = r.offsetTop;
          lyricsContainer.scrollTo({
            top: rowTop - (containerHeight / 2) + (r.clientHeight / 2),
            behavior: 'smooth'
          });
        }
      } else {
        r.classList.remove('active');
      }
    });
  }

  function togglePlay() {
    isPlaying = !isPlaying;
    const icon = playBtn.querySelector('i');

    if (isPlaying) {
      icon.className = 'fas fa-pause';
      if (soundwave) soundwave.classList.remove('paused');
      playInterval = setInterval(() => {
        const song = demoPlaylist[currentSongIndex];
        currentTime += 0.5;
        if (currentTime >= song.duration) {
          nextSong();
        } else {
          updateProgress();
          updateActiveLyric();
        }
      }, 500);
    } else {
      icon.className = 'fas fa-play';
      if (soundwave) soundwave.classList.add('paused');
      clearInterval(playInterval);
    }
  }

  function nextSong() {
    currentSongIndex = (currentSongIndex + 1) % demoPlaylist.length;
    loadSong(currentSongIndex);
  }

  function prevSong() {
    if (currentTime > 3) {
      currentTime = 0;
      updateProgress();
      updateActiveLyric();
      return;
    }
    currentSongIndex = (currentSongIndex - 1 + demoPlaylist.length) % demoPlaylist.length;
    loadSong(currentSongIndex);
  }

  // Seek bar click
  if (progressTrack) {
    progressTrack.addEventListener('click', (e) => {
      const rect = progressTrack.getBoundingClientRect();
      const clickPos = (e.clientX - rect.left) / rect.width;
      const song = demoPlaylist[currentSongIndex];
      currentTime = clickPos * song.duration;
      updateProgress();
      updateActiveLyric();
    });
  }

  // Favorite Heart Smooth Spring Toggle
  let isFav = false;
  if (favoriteBtn) {
    favoriteBtn.addEventListener('click', () => {
      isFav = !isFav;
      const heartIcon = favoriteBtn.querySelector('i');
      favoriteBtn.style.transform = 'scale(1.45)';
      setTimeout(() => {
        favoriteBtn.style.transform = 'scale(1.0)';
      }, 220);

      if (isFav) {
        heartIcon.className = 'fas fa-heart';
        heartIcon.style.color = '#FC3C44';
      } else {
        heartIcon.className = 'far fa-heart';
        heartIcon.style.color = 'rgba(255,255,255,0.7)';
      }
    });
  }

  playBtn.addEventListener('click', togglePlay);
  nextBtn.addEventListener('click', nextSong);
  prevBtn.addEventListener('click', prevSong);

  // Tab Song Pills click
  songPills.forEach((pill, idx) => {
    pill.addEventListener('click', () => {
      loadSong(idx);
      if (!isPlaying) togglePlay();
    });
  });

  // FAQ Accordion Toggles
  const faqCards = document.querySelectorAll('.faq-card');
  faqCards.forEach((card) => {
    card.addEventListener('click', () => {
      const isOpen = card.classList.contains('open');
      faqCards.forEach(c => c.classList.remove('open'));
      if (!isOpen) {
        card.classList.add('open');
      }
    });
  });

  // Mobile Navigation Menu Toggle
  const navToggle = document.getElementById('nav-toggle');
  const navLinks = document.querySelector('.nav-links');
  if (navToggle && navLinks) {
    navToggle.addEventListener('click', () => {
      navLinks.classList.toggle('active');
      const icon = navToggle.querySelector('i');
      if (icon) {
        if (navLinks.classList.contains('active')) {
          icon.className = 'fas fa-xmark';
        } else {
          icon.className = 'fas fa-bars';
        }
      }
    });

    // Close menu when tapping any link
    navLinks.querySelectorAll('a').forEach(link => {
      link.addEventListener('click', () => {
        navLinks.classList.remove('active');
        const icon = navToggle.querySelector('i');
        if (icon) icon.className = 'fas fa-bars';
      });
    });
  }

  // Initialize first song
  loadSong(0);
});
