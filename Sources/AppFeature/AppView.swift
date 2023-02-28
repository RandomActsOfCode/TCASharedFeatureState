import ComposableArchitecture
import FooFeature
import Foundation
import SwiftUI

// MARK: - AppView

public struct AppView: View {
  // MARK: Lifecycle

  public init(store: StoreOf<AppFeature>) {
    self.store = store
  }

  // MARK: Public

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack {
        titleText
        Spacer()
        temperatureText
        childFeatureSheetButton
        Spacer()
      }
      .childFeatureSheet(store)
      .task { viewStore.send(.task) }
    }
  }

  // MARK: Private

  private let store: StoreOf<AppFeature>

  private var titleText: some View {
    Text("App Feature")
      .font(.headline)
      .padding()
  }

  private var temperatureText: some View {
    WithViewStore(store, observe: \.temperatureString) { viewStore in
      Text("Temperature: \(viewStore.state)")
        .padding()
    }
  }

  private var childFeatureSheetButton: some View {
    WithViewStore(store.stateless) { viewStore in
      Button(action: { viewStore.send(.gotoChildButtonPressed) }) {
        Text("Goto Foo Feature")
      }
    }
  }
}

extension View {
  fileprivate func childFeatureSheet(_ store: StoreOf<AppFeature>) -> some View {
    WithViewStore(store, observe: \.showFooFeatureSheet) { viewStore in
      sheet(
        isPresented: viewStore.binding(
          get: { $0 },
          send: AppFeature.Action.fooFeatureSheetDismissed
        )
      ) {
        IfLetStore(store.scope(state: \.foo, action: AppFeature.Action.foo(action:))) { store in
          FooFeatureView(store: store)
        }
      }
    }
  }
}
