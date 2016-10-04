import Foundation

open class Container: UIBaseObject {
    open internal(set) var ready = false
    open internal(set) var dvrInUse = false
    open internal(set) var settings: [String : AnyObject] = [:]
    open internal(set) var plugins: [UIContainerPlugin] = []
    open internal(set) var options: Options
    
    fileprivate var loader: Loader
    
    open var isPlaying: Bool {
        return playback.isPlaying
    }
    
    open var mediaControlEnabled = false {
        didSet {
            let eventToTrigger: ContainerEvent = mediaControlEnabled ? .MediaControlEnabled : .MediaControlDisabled
            trigger(eventToTrigger)
        }
    }
    
    open internal(set) var playback: Playback {
        didSet {
            stopListening()
            bindEventListeners()
        }
    }

    public init(playback: Playback, loader: Loader = Loader(), options: Options = [:]) {
        Logger.logDebug("loading with \(options)", scope: "\(type(of: self))")
        self.playback = playback
        self.options = options
        self.loader = loader
        super.init(frame: CGRect.zero)
        self.backgroundColor = UIColor.clear
        bindEventListeners()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("Use init(playback: Playback) instead")
    }
    
    open func load(_ source: String, mimeType: String? = nil) {
        var playbackOptions = options
        playbackOptions[kSourceUrl] = source as AnyObject?
        playbackOptions[kMimeType] = mimeType as AnyObject?? ?? nil
        
        let playbackFactory = PlaybackFactory(loader: loader, options: playbackOptions)
        
        playback.removeFromSuperview()
        playback = playbackFactory.createPlayback()
        renderPlayback()
        trigger(ContainerEvent.SourceChanged)
    }
    
    open override func render() {
        plugins.forEach(renderPlugin)
        renderPlayback()
    }
    
    fileprivate func renderPlayback() {
        addSubviewMatchingConstraints(playback)
        playback.render()
        sendSubview(toBack: playback)
    }
    
    fileprivate func renderPlugin(_ plugin: UIContainerPlugin) {
        addSubview(plugin)
        plugin.render()
    }
    
    open func destroy() {
        stopListening()
        playback.destroy()
        
        removeFromSuperview()
    }
    
    open func play() {
        playback.play()
    }
    
    open func pause() {
        playback.pause()
    }
    
    open func stop() {
        playback.stop()
        trigger(ContainerEvent.Stop)
    }
    
    open func seek(_ timeInterval: TimeInterval) {
        playback.seek(timeInterval)
    }
    
    open func addPlugin(_ plugin: UIContainerPlugin) {
        plugins.append(plugin)
    }
    
    open func hasPlugin(_ pluginClass: AnyClass) -> Bool {
        return plugins.filter({$0.isKind(of: pluginClass)}).count > 0
    }
    
    fileprivate func bindEventListeners() {
        for (event, callback) in eventBindings() {
            listenTo(playback, eventName: event.rawValue, callback: callback)
        }
    }
    
    fileprivate func eventBindings() -> [PlaybackEvent : EventCallback] {
        return [
            .Buffering              : { [weak self] (info: EventUserInfo) in self?.trigger(.Buffering)} as EventCallback,
            .BufferFull             : { [weak self] (info: EventUserInfo) in self?.trigger(.BufferFull)} as EventCallback,
            .HighDefinitionUpdated  : { [weak self] (info: EventUserInfo) in self?.trigger(.HighDefinitionUpdated)} as EventCallback,
            .StateChanged           : { [weak self] (info: EventUserInfo) in self?.trigger(.PlaybackStateChanged)} as EventCallback,
            .Ended                  : { [weak self] (info: EventUserInfo) in self?.trigger(.Ended)} as EventCallback,
            .Play                   : { [weak self] (info: EventUserInfo) in self?.onPlay()} as EventCallback,
            .Pause                  : { [weak self] (info: EventUserInfo) in self?.trigger(.Pause)} as EventCallback,
            .MediaControlDisabled   : { [weak self] (info: EventUserInfo) in self?.mediaControlEnabled = false } as EventCallback,
            .MediaControlEnabled    : { [weak self] (info: EventUserInfo) in self?.mediaControlEnabled = true } as EventCallback,
            .SettingsUpdated        : { [weak self] (info: EventUserInfo) in self?.settingsUpdated()} as EventCallback,
            .Ready                  : { [weak self] (info: EventUserInfo) in self?.setReady() } as EventCallback,
            .DVRStateChanged        : { [weak self] (info: EventUserInfo) in self?.setDvrInUse(info) } as EventCallback,
            .Progress               : { [weak self] (info: EventUserInfo) in self?.forward(.Progress, userInfo:info)} as EventCallback,
            .TimeUpdated            : { [weak self] (info: EventUserInfo) in self?.forward(.TimeUpdated, userInfo:info)} as EventCallback,
            .LoadedMetadata         : { [weak self] (info: EventUserInfo) in self?.forward(.LoadedMetadata, userInfo:info)} as EventCallback,
            .SubtitleSourcesUpdated : { [weak self] (info: EventUserInfo) in self?.forward(.SubtitleSourcesUpdated, userInfo:info)} as EventCallback,
            .AudioSourcesUpdated    : { [weak self] (info: EventUserInfo) in self?.forward(.AudioSourcesUpdated, userInfo:info)} as EventCallback,
            .BitRate                : { [weak self] (info: EventUserInfo) in self?.forward(.BitRate, userInfo:info)} as EventCallback,
            .Error                  : { [weak self] (info: EventUserInfo) in self?.forward(.Error, userInfo:info)} as EventCallback,
        ]
    }

    fileprivate func onPlay() {
        options[kStartAt] = 0 as AnyObject?
        trigger(.Play)
    }
    
    fileprivate func settingsUpdated() {
        settings = playback.settings
        self.trigger(ContainerEvent.SettingsUpdated)
    }
    
    fileprivate func setReady() {
        ready = true
        trigger(ContainerEvent.Ready)
    }
    
    fileprivate func setDvrInUse(_ userInfo: EventUserInfo) {
        settingsUpdated()
        
        if let playbackDvrInUse = userInfo!["dvr_in_use"] as? Bool {
            dvrInUse = playbackDvrInUse
        }
        
        forward(ContainerEvent.PlaybackDVRStateChanged, userInfo: userInfo)
    }
    
    fileprivate func trigger(_ event: ContainerEvent) {
        trigger(event.rawValue)
    }
    
    fileprivate func forward(_ event: ContainerEvent, userInfo: EventUserInfo) {
        trigger(event.rawValue, userInfo: userInfo)
    }
}
