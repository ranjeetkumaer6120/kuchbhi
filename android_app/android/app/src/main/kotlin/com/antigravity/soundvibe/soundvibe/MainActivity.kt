package com.antigravity.soundvibe.soundvibe

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.android.RenderMode

class MainActivity : AudioServiceActivity() {
    // RenderMode.texture allows seamless video compositing and mirroring
    // across Car Displays (Android Auto, MirrorLink, ZLink, USB DisplayPort)
    // without the black screen bug caused by standard SurfaceView.
    override fun getRenderMode(): RenderMode = RenderMode.texture
}
