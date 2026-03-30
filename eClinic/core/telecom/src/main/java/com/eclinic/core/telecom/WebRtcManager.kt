package com.eclinic.core.telecom

import android.content.Context
import org.webrtc.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class WebRtcManager @Inject constructor(
    private val context: Context
) {
    private var peerConnectionFactory: PeerConnectionFactory? = null
    private val eglBase: EglBase = EglBase.create()

    init {
        initPeerConnectionFactory(context)
    }

    private fun initPeerConnectionFactory(context: Context) {
        val options = PeerConnectionFactory.InitializationOptions.builder(context)
            .setEnableInternalTracer(true)
            .setFieldTrials("WebRTC-H264HighProfile/Enabled/")
            .createInitializationOptions()
        PeerConnectionFactory.initialize(options)

        val encoderFactory = DefaultVideoEncoderFactory(eglBase.eglBaseContext, true, true)
        val decoderFactory = DefaultVideoDecoderFactory(eglBase.eglBaseContext)

        peerConnectionFactory = PeerConnectionFactory.builder()
            .setVideoEncoderFactory(encoderFactory)
            .setVideoDecoderFactory(decoderFactory)
            .setOptions(PeerConnectionFactory.Options().apply {
                disableEncryption = false
                disableNetworkMonitor = false
            })
            .createPeerConnectionFactory()
    }

    fun createPeerConnection(
        iceServers: List<PeerConnection.IceServer>,
        observer: PeerConnection.Observer
    ): PeerConnection? {
        val rtcConfig = PeerConnection.RTCConfiguration(iceServers)
        rtcConfig.sdpSemantics = PeerConnection.SdpSemantics.UNIFIED_PLAN
        return peerConnectionFactory?.createPeerConnection(rtcConfig, observer)
    }

    fun createVideoSource(isScreencast: Boolean): VideoSource? {
        return peerConnectionFactory?.createVideoSource(isScreencast)
    }

    fun createVideoTrack(id: String, source: VideoSource): VideoTrack? {
        return peerConnectionFactory?.createVideoTrack(id, source)
    }

    fun createAudioSource(constraints: MediaConstraints): AudioSource? {
        return peerConnectionFactory?.createAudioSource(constraints)
    }

    fun createAudioTrack(id: String, source: AudioSource): AudioTrack? {
        return peerConnectionFactory?.createAudioTrack(id, source)
    }

    fun getEglBaseContext(): EglBase.Context = eglBase.eglBaseContext

    fun dispose() {
        peerConnectionFactory?.dispose()
        eglBase.release()
    }
}
