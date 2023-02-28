import AppFeature
import ComposableArchitecture
import SwiftUI

@main
struct ExampleApp: App {
  // MARK: Internal

  var body: some Scene {
    WindowGroup {
      AppView(store: store)
    }
  }

  // MARK: Private

  private var store = StoreOf<AppFeature>(
    initialState: .init(),
    reducer: AppFeature()
  )
}
