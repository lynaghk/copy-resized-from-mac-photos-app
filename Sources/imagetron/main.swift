import Cocoa
import Foundation
import PhotoPasteboardLib

// Custom view for draggable thumbnails with hover effect
class DraggableThumbnailView: NSView {
  private let imageView: NSImageView
  private let imageURL: URL
  private var trackingArea: NSTrackingArea?
  private var isHovered = false

  init(frame: NSRect, imageURL: URL) {
    self.imageURL = imageURL
    self.imageView = NSImageView(frame: NSRect(origin: .zero, size: frame.size))

    super.init(frame: frame)

    // Configure image view
    if let image = NSImage(contentsOf: imageURL) {
      imageView.image = image
      imageView.imageScaling = .scaleProportionallyUpOrDown
    }

    addSubview(imageView)

    // Enable dragging
    registerForDraggedTypes([.fileURL])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func updateTrackingAreas() {
    super.updateTrackingAreas()

    if let trackingArea = trackingArea {
      removeTrackingArea(trackingArea)
    }

    trackingArea = NSTrackingArea(
      rect: bounds,
      options: [.mouseEnteredAndExited, .activeAlways],
      owner: self,
      userInfo: nil
    )

    if let trackingArea = trackingArea {
      addTrackingArea(trackingArea)
    }
  }

  override func mouseEntered(with event: NSEvent) {
    isHovered = true
    needsDisplay = true
  }

  override func mouseExited(with event: NSEvent) {
    isHovered = false
    needsDisplay = true
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    if isHovered {
      // Draw rounded background when hovered
      NSColor.selectedContentBackgroundColor.withAlphaComponent(0.3).setFill()
      let path = NSBezierPath(roundedRect: bounds, xRadius: 4, yRadius: 4)
      path.fill()
    }
  }

  override func mouseDown(with event: NSEvent) {
    // Accept the mouse down to enable dragging
  }

  override func mouseDragged(with event: NSEvent) {
    // Create drag session
    let draggingItem = NSDraggingItem(pasteboardWriter: imageURL as NSURL)

    // Set the drag image to the thumbnail
    if let image = imageView.image {
      draggingItem.setDraggingFrame(bounds, contents: image)
    }

    // Begin dragging session
    beginDraggingSession(with: [draggingItem], event: event, source: self)
  }
}

extension DraggableThumbnailView: NSDraggingSource {
  func draggingSession(
    _ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext
  ) -> NSDragOperation {
    return [.copy, .move]
  }
}

// Custom view for dragging all cached files
class DragAllFilesView: NSView {
  private let imageURLs: [URL]
  private let label: NSTextField
  private var trackingArea: NSTrackingArea?
  private var isHovered = false

  init(frame: NSRect, imageURLs: [URL]) {
    self.imageURLs = imageURLs
    self.label = NSTextField(labelWithString: "⬇︎ Drag All Images (\(imageURLs.count))")

    super.init(frame: frame)

    // Configure label
    label.frame = NSRect(x: 10, y: 5, width: frame.width - 20, height: 20)
    label.alignment = .center
    label.textColor = .secondaryLabelColor
    label.font = .systemFont(ofSize: 13)
    addSubview(label)

    // Enable dragging
    registerForDraggedTypes([.fileURL])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func updateTrackingAreas() {
    super.updateTrackingAreas()

    if let trackingArea = trackingArea {
      removeTrackingArea(trackingArea)
    }

    trackingArea = NSTrackingArea(
      rect: bounds,
      options: [.mouseEnteredAndExited, .activeAlways],
      owner: self,
      userInfo: nil
    )

    if let trackingArea = trackingArea {
      addTrackingArea(trackingArea)
    }
  }

  override func mouseEntered(with event: NSEvent) {
    isHovered = true
    label.textColor = .labelColor
    needsDisplay = true
  }

  override func mouseExited(with event: NSEvent) {
    isHovered = false
    label.textColor = .secondaryLabelColor
    needsDisplay = true
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    if isHovered {
      // Draw rounded background when hovered
      NSColor.selectedContentBackgroundColor.withAlphaComponent(0.2).setFill()
      let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 5, dy: 2), xRadius: 4, yRadius: 4)
      path.fill()
    }
  }

  override func mouseDown(with event: NSEvent) {
    // Accept the mouse down to enable dragging
  }

  override func mouseDragged(with event: NSEvent) {
    guard !imageURLs.isEmpty else { return }

    // Create a single drag image for all files
    guard
      let dragImage = NSImage(systemSymbolName: "doc.on.doc.fill", accessibilityDescription: nil)
    else {
      return
    }
    dragImage.size = NSSize(width: 32, height: 32)

    // Create dragging items for all files
    var draggingItems: [NSDraggingItem] = []

    for url in imageURLs {
      let item = NSDraggingItem(pasteboardWriter: url as NSURL)
      // Set the same dragging frame for all items
      item.setDraggingFrame(
        NSRect(x: bounds.midX - 16, y: bounds.midY - 16, width: 32, height: 32),
        contents: dragImage
      )
      draggingItems.append(item)
    }

    // Begin dragging session
    beginDraggingSession(with: draggingItems, event: event, source: self)
  }
}

extension DragAllFilesView: NSDraggingSource {
  func draggingSession(
    _ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext
  ) -> NSDragOperation {
    return [.copy, .move]
  }
}

// Custom status bar button view that supports dragging
class DraggableStatusBarView: NSView {
  weak var appDelegate: AppDelegate?
  private var imageView: NSImageView!
  private var textField: NSTextField!

  override init(frame: NSRect) {
    super.init(frame: frame)
    setupViews()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupViews()
  }

  private func setupViews() {
    imageView = NSImageView(frame: NSRect(x: 2, y: 2, width: 18, height: 18))
    if let image = NSImage(systemSymbolName: "photo", accessibilityDescription: "Imagetron") {
      image.isTemplate = true
      imageView.image = image
    }
    addSubview(imageView)

    textField = NSTextField(labelWithString: "")
    textField.font = .menuBarFont(ofSize: 0)
    textField.isBordered = false
    textField.isEditable = false
    textField.isSelectable = false
    textField.drawsBackground = false
    addSubview(textField)
  }

  func updateCount(_ count: Int) {
    if count > 0 {
      textField.stringValue = " \(count)"
    } else {
      textField.stringValue = ""
    }
    textField.sizeToFit()

    // Adjust frame to fit icon + text
    let totalWidth = 22 + textField.frame.width
    frame = NSRect(x: 0, y: 0, width: totalWidth, height: 22)
    textField.frame = NSRect(
      x: 20, y: 4, width: textField.frame.width, height: textField.frame.height)

    // Update the status item length
    if let statusItem = appDelegate?.statusItem {
      statusItem.length = totalWidth
    }
  }

  override func mouseDown(with event: NSEvent) {
    // Store the event for potential drag
  }

  override func mouseDragged(with event: NSEvent) {
    guard let appDelegate = appDelegate else { return }

    let cacheDir = appDelegate.getCacheDirectory()
    let allImages = appDelegate.getRecentImages(from: cacheDir, limit: 20)

    guard !allImages.isEmpty else { return }

    // Create a single drag image for all files
    guard
      let dragImage = NSImage(systemSymbolName: "doc.on.doc.fill", accessibilityDescription: nil)
    else {
      return
    }
    dragImage.size = NSSize(width: 32, height: 32)

    // Create dragging items for all files
    var draggingItems: [NSDraggingItem] = []

    for url in allImages {
      let item = NSDraggingItem(pasteboardWriter: url as NSURL)
      item.setDraggingFrame(
        NSRect(x: 0, y: 0, width: 32, height: 32),
        contents: dragImage
      )
      draggingItems.append(item)
    }

    // Begin dragging session
    beginDraggingSession(with: draggingItems, event: event, source: self)
  }

  override func mouseUp(with event: NSEvent) {
    // If we got a mouseUp without a drag, treat it as a click to show menu
    appDelegate?.showMenu()
  }
}

extension DraggableStatusBarView: NSDraggingSource {
  func draggingSession(
    _ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext
  ) -> NSDragOperation {
    return [.copy, .move]
  }
}

class AppDelegate: NSObject, NSApplicationDelegate {
  var statusItem: NSStatusItem!
  var statusBarView: DraggableStatusBarView!
  var lastCheckedChangeCount = 0

  // Check if jpegoptim is installed in PATH
  func isJpegoptimInstalled() -> Bool {
    return findJpegoptim() != nil
  }

  // Show alert dialog when jpegoptim is missing
  func showJpegoptimMissingAlert() {
    let alert = NSAlert()
    alert.messageText = "jpegoptim Not Found"
    alert.informativeText =
      "Imagetron requires jpegoptim to optimize images.\n\nPlease install it using:\n\nbrew install jpegoptim\n\nor\n\nsudo port install jpegoptim"
    alert.alertStyle = .warning
    alert.addButton(withTitle: "OK")
    alert.runModal()
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    // Simple logging for dev
    // let logPath = NSHomeDirectory() + "/imagetron.log"
    // freopen(logPath.cString(using: .utf8), "a+", stdout)
    // setbuf(stdout, nil)  // no buffering

    print("Imagetron started at \(Date())")

    // Check for jpegoptim on startup
    if !isJpegoptimInstalled() {
      showJpegoptimMissingAlert()
      NSApp.terminate(nil)
      return
    }

    // Setup menu bar with custom view
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    statusBarView = DraggableStatusBarView(frame: NSRect(x: 0, y: 0, width: 22, height: 22))
    statusBarView.appDelegate = self
    statusItem.button?.addSubview(statusBarView)

    // Create menu (will be rebuilt dynamically)
    rebuildMenu()

    // Watch pasteboard
    startPasteboardMonitoring()
  }

  func showMenu() {
    statusItem.button?.performClick(nil)
  }

  func getCacheDirectory() -> URL {
    let bundleID = Bundle.main.bundleIdentifier!
    return FileManager.default.temporaryDirectory
      .appendingPathComponent(bundleID, isDirectory: true)
  }

  func rebuildMenu() {
    let menu = NSMenu()

    // Get recent images from cache (limit 20 for display)
    let cacheDir = getCacheDirectory()
    let recentImages = getRecentImages(from: cacheDir, limit: 20)

    // Update menu bar icon with badge count
    updateMenuBarIcon(count: recentImages.count)

    if !recentImages.isEmpty {
      // Create thumbnail grid view
      let thumbnailView = createThumbnailGridView(images: recentImages)
      let containerItem = NSMenuItem()
      containerItem.view = thumbnailView
      menu.addItem(containerItem)

      menu.addItem(NSMenuItem.separator())
    } else {
      let noPhotosItem = NSMenuItem(title: "No cached photos", action: nil, keyEquivalent: "")
      noPhotosItem.isEnabled = false
      menu.addItem(noPhotosItem)
      menu.addItem(NSMenuItem.separator())
    }

    // Add copy and clear cache options
    menu.addItem(
      NSMenuItem(
        title: "Copy All to Clipboard", action: #selector(copyToClipboard), keyEquivalent: "c"))
    menu.addItem(NSMenuItem(title: "Clear Cache", action: #selector(clearCache), keyEquivalent: ""))
    menu.addItem(NSMenuItem.separator())
    menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

    statusItem.menu = menu
  }

  func getRecentImages(from directory: URL, limit: Int) -> [URL] {
    guard
      let enumerator = FileManager.default.enumerator(
        at: directory,
        includingPropertiesForKeys: [.contentModificationDateKey],
        options: [.skipsHiddenFiles]
      )
    else {
      return []
    }

    var imageFiles: [(url: URL, date: Date)] = []

    for case let fileURL as URL in enumerator {
      guard fileURL.pathExtension.lowercased() == "jpg" else { continue }

      if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
        let modDate = attributes[.modificationDate] as? Date
      {
        imageFiles.append((url: fileURL, date: modDate))
      }
    }

    // Sort by modification date (most recent first) and limit
    return
      imageFiles
      .sorted { $0.date > $1.date }
      .prefix(limit)
      .map { $0.url }
  }

  func createThumbnailGridView(images: [URL]) -> NSView {
    let thumbnailSize: CGFloat = 80
    let spacing: CGFloat = 8
    let columns = 4
    let rows = min((images.count + columns - 1) / columns, 5)  // Max 5 rows

    let width = CGFloat(columns) * (thumbnailSize + spacing) + spacing
    let height = CGFloat(rows) * (thumbnailSize + spacing) + spacing

    let containerView = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))

    for (index, imageURL) in images.prefix(columns * rows).enumerated() {
      let row = index / columns
      let col = index % columns

      let x = spacing + CGFloat(col) * (thumbnailSize + spacing)
      let y = height - spacing - CGFloat(row + 1) * (thumbnailSize + spacing)

      let thumbnailContainer = DraggableThumbnailView(
        frame: NSRect(x: x, y: y, width: thumbnailSize, height: thumbnailSize),
        imageURL: imageURL
      )

      containerView.addSubview(thumbnailContainer)
    }

    return containerView
  }

  @objc func clearCache() {
    let cacheDir = getCacheDirectory()

    do {
      let fileURLs = try FileManager.default.contentsOfDirectory(
        at: cacheDir,
        includingPropertiesForKeys: nil
      )

      for fileURL in fileURLs {
        try FileManager.default.removeItem(at: fileURL)
      }

      print("Cleared cache: \(fileURLs.count) file(s) deleted")
      rebuildMenu()
    } catch {
      print("Failed to clear cache: \(error)")
    }
  }

  func startPasteboardMonitoring() {
    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      guard let self = self else { return }

      let pasteboard = NSPasteboard.general
      if pasteboard.changeCount != self.lastCheckedChangeCount {
        self.lastCheckedChangeCount = pasteboard.changeCount
        print("Pasteboard changed: \(self.lastCheckedChangeCount)")

        // Update menu asynchronously
        Task {
          await self.updatePhotoInfo()
        }
      }
    }

    // Initial check
    Task {
      await self.updatePhotoInfo()
    }
  }

  func updatePhotoInfo() async {
    if let photoInfos = await getPhotosWithMetadataFromPasteboard() {
      // Process and save images
      let tempDir = getCacheDirectory()

      // Create directory if it doesn't exist
      try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"

      var savedFileURLs: [URL] = []

      for (index, photoInfo) in photoInfos.enumerated() {
        // Resize image
        let resizedImage = resizeImage(photoInfo.image)

        // Generate filename from creation date
        let dateString: String
        if let creationDate = photoInfo.creationDate {
          dateString = dateFormatter.string(from: creationDate)
        } else {
          dateString = dateFormatter.string(from: Date())
        }

        // Add index suffix if multiple photos have same timestamp
        let filename = "\(dateString)_\(index + 1).jpg"
        let fileURL = tempDir.appendingPathComponent(filename)

        // Save image
        if saveImageAsJPEG(resizedImage, to: fileURL) {
          savedFileURLs.append(fileURL)
          print("Saved: \(fileURL.path)")
        }
      }

      print("Saved \(savedFileURLs.count) photo(s) to cache")

      // Copy all cached images to pasteboard
      await MainActor.run {
        self.copyAllCachedImagesToPasteboard()
        self.rebuildMenu()
      }
    }
  }

  func copyAllCachedImagesToPasteboard() {
    let cacheDir = getCacheDirectory()
    let allImages = getRecentImages(from: cacheDir, limit: 20)

    guard !allImages.isEmpty else { return }

    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()

    // Write all image URLs to pasteboard
    pasteboard.writeObjects(allImages as [NSURL])

    print("Copied \(allImages.count) image(s) to pasteboard")
  }

  @objc func copyToClipboard() {
    copyAllCachedImagesToPasteboard()
  }

  func updateMenuBarIcon(count: Int) {
    statusBarView.updateCount(count)
  }

  @objc func quit() {
    NSApp.terminate(nil)
  }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
