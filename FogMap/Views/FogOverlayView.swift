import MapKit

/// A simple overlay that covers the entire world.
final class FogOverlay: NSObject, MKOverlay {
  // Apple Maps requires a coordinate for the overlay.
  // We can pick (0,0) or any arbitrary coordinate.
  var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)

  // boundingMapRect covers the entire Earth.
  var boundingMapRect: MKMapRect = MKMapRect.world
}

/// The custom renderer draws a semi-transparent black fill everywhere,
/// subtracting circles where the user has visited.
final class FogOverlayRenderer: MKOverlayRenderer {
  /// The visited locations displayed as “holes” in the black overlay.
  var visitedLocations: [VisitedLocation]

  init(overlay: MKOverlay, visitedLocations: [VisitedLocation]) {
    self.visitedLocations = visitedLocations
    super.init(overlay: overlay)
  }

  private final class Info {
    let image: CGImage
    let dynamicTileSize: CGSize

    init(image: CGImage, dynamicTileSize: CGSize) {
      self.image = image
      self.dynamicTileSize = dynamicTileSize
    }
  }

  override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
    guard let overlay = overlay as? FogOverlay else { return }

    // 1) Load the noise tile (UIImage or CGImage in your assets)
    guard let noiseImage = UIImage(named: "noise")?.cgImage else { return }

    context.saveGState()

    // 2) Fill the entire bounding rect with black (optional), or start with white
    let entireRect = rect(for: overlay.boundingMapRect)
    context.setFillColor(UIColor.black.cgColor)
    context.fill(entireRect)

    // 3) Create a pattern from the noise tile
    var callbacks = CGPatternCallbacks(version: 0, drawPattern: { info, ctx in
      let info = Unmanaged<Info>.fromOpaque(info!).takeUnretainedValue()
      // Paint the tile once in the pattern space
      ctx.draw(info.image, in: CGRect(origin: .zero, size: info.dynamicTileSize))
    }, releaseInfo: { info in
      Unmanaged<Info>.fromOpaque(info!).release()
    })

    let tileSize = CGSize(width: CGFloat(noiseImage.width) * (1 / zoomScale), height: CGFloat(noiseImage.height) * (1 / zoomScale))
    guard let patternSpace = CGColorSpace(patternBaseSpace: nil),
          let pattern = CGPattern(
            info: Unmanaged.passRetained(Info(image: noiseImage, dynamicTileSize: tileSize)).toOpaque(),
            bounds: CGRect(origin: .zero, size: tileSize),
            matrix: .identity,
            xStep: tileSize.width,
            yStep: tileSize.height,
            tiling: .constantSpacing,
            isColored: true,
            callbacks: &callbacks
          ) else {
      context.restoreGState()
      return
    }

    context.saveGState()
    context.setFillColorSpace(patternSpace)
    // Alpha of 0.5 => 50% visible noise
    var alpha : CGFloat = 0.1
    context.setFillPattern(pattern, colorComponents: &alpha)

    // Fill the bounding rect with the noise pattern
    context.fill(entireRect)
    context.restoreGState()

    // 4) Subtract circles for each visited location
    context.setBlendMode(.destinationOut)

    for location in visitedLocations {
      guard let latitude = location.latitude, let longitude = location.longitude else { continue }
      let mapPoint = MKMapPoint(CLLocationCoordinate2D(
        latitude: latitude,
        longitude: longitude))

      let point = rect(for: MKMapRect(origin: mapPoint, size: MKMapSize(width: 0, height: 0)))

      let circlePath = UIBezierPath(ovalIn: point.insetBy(dx: -600, dy: -600))

      context.addPath(circlePath.cgPath)
      context.fillPath()
    }

    context.restoreGState()
  }
}
