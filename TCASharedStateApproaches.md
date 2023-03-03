# Approaches for Managing Shared State in TCA Applications

- [Approaches for Managing Shared State in TCA Applications](#approaches-for-managing-shared-state-in-tca-applications)
  - [Vanilla](#vanilla)
    - [Description](#description)
    - [Example](#example)
    - [Consequences](#consequences)
      - [Cons](#cons)
      - [Pros](#pros)
  - [Synchronize not Share](#synchronize-not-share)
    - [Description](#description-1)
    - [Example](#example-1)
    - [Consequences](#consequences-1)
      - [Pros](#pros-1)
      - [Cons](#cons-1)
  - [Boxed State](#boxed-state)
    - [Description](#description-2)
    - [Example](#example-2)
    - [Consequences](#consequences-2)
      - [Pros](#pros-2)
      - [Cons](#cons-2)
  - [Synchronize with a Dependency](#synchronize-with-a-dependency)
    - [Example](#example-3)
    - [Consequences](#consequences-3)
      - [Pros](#pros-3)
      - [Cons](#cons-3)
  - [Use the Client Directly](#use-the-client-directly)
    - [Example](#example-4)
    - [Consequences](#consequences-4)
    - [Pros](#pros-4)
    - [Cons](#cons-4)

## Vanilla

### Description

- Child feature properties and inlined into parent feature `State`
- One or more properties in the parent `State` are to be shared
- Parent `State` provides computed properties to compose child `State` by
joining the child state with the shared `State`

### Example

```swift
struct ParentState {
  var someValue: A
  var someSharedValue: B
  var someChildValue: C
  var someOtherChildValue: D
}

extension ParentState {
    var someChild: ChildState {
        // glue parent shared state with child state together
        .init(someSharedValue, someChildValue)
    }

    var someOtherChild: OtherChildState {
        // glue parent shared state with child state together
        .init(someSharedValue, someOtherChildValue)
    }
}

struct ChildState {
    var someSharedValue: B
    var someChildValue: C
}

struct OtherChildState {
    var someSharedValue: B
    var someOtherChildValue: D
}
```

### Consequences

#### Cons

- The parent feature's `State` will contain a union of all properties for all
child features combined with its own properties (shared or otherwise)
- This has a "viral" effect that causes all properties to be pushed up the
feature hierarchy with the state getting larger and larger as you move up the
hierarchy
- This does not scale - we have had features with more than a 100 loose
properties all mixed together
- The cascading update of `State` also does not scale - adding a single property
can result in many features needing to be updated as the new property is
propagated up the feature hierarchy

#### Pros

- No synchronization necessary: all child features will always have shared
`State` kept in sync to the parent's `State` and is not possible to get this
wrong (i.e. compile time enforcement)

## Synchronize not Share

### Description

- Always embed the shared `State` in any feature that needs it
- No computed properties are used to compose state
- Manually synchronize the shared state on updates

### Example

```swift
struct ParentState {
  var someValue: A
  var someSharedValue: B
  var someChild: ChildState
  var someOtherChildState: OtherChildState
}

// Parent's reducer
func core(into state: inout State, action: Action) -> EffectTask<Action> {
    case .sharedValueUpdated(let newValue):
      state.someSharedValue = newValue
      state.someChild.someSharedValue = newValue
      state.someOtherChildValue.someSharedValue = newValue
      return .none
}

struct ChildState {
   var someSharedValue: B {
       didSet {
           // set any child state's someSharedValue
       }
   }
   var someChildValue: C
}

struct OtherChildState {
   var someSharedValue: B {
       didSet {
           // set any child state's someSharedValue
       }
   }
   var someOtherChildValue: D
}
```

### Consequences

#### Pros

- Does not suffer from the explosion of loose properties with the vanilla
approach

#### Cons

- Prone to bugs since it is easy to miss a child state when updating the value
- Using `didSet` on `State` properties is a TCA anti-pattern since it does not
play well with `TestStore` (see the
[RFC](https://github.com/pointfreeco/swift-composable-architecture/discussions/1666))
- Easy to forget or overlook that a `didSet` hook must be added depending on
where in the feature hierarchy a new feature is being added (runtime error)
- Has a viral effect for `didSet` which must be added along the full feature
chain
- Adds boilerplate through the `didSet` function (which should actually be a
`setSharedState(value:)` function)

## Boxed State

### Description

- Manage the complexity of the vanilla approach by partitioning all the
properties of a child feature into those that are owned by the feature and those
that are not (i.e. shared)
- The parent feature holds onto a child feature's owned `State` through a "box"
type, and composes with the shared state to create child state
- Wrapper types are provided to unify the shared and box state for better
ergonomics (i.e. by making use of `@dynamicMemberLookup`)

### Example

```swift
struct ParentState {
  var someValue: A
  var someSharedValue: B                     // owned by Parent
  var someChild: ChildState.Boxed            // owned by Child
  var someOtherChild: OtherChildState.Boxed  // owned by OtherChild
}

extension ParentState {
    var someChild: ChildState {
        .init(shared: .init(someSharedValue), boxed: someChild)
    }

    var someOtherChild: OtherChildState {
        .init(shared: .init(someSharedValue), boxed: someOtherChild)
    }
}

struct ChildState {
    struct Shared {
      var someSharedValue: B
    }
    struct Boxed {
      var someChildValue: C
    }

    var shared: Shared
    var boxed: Boxed
}

struct OtherChildState {
    struct Shared {
      var someSharedValue: B
    }
    struct Boxed {
      var someOtherChildValue: D
    }

    var shared: Shared
    var boxed: Boxed
}
```

### Consequences

#### Pros

- Addresses the issue with the vanilla approach by managing the complexity for
large features: all properties are "boxed" appropriately
- Shared `State` is automatically kept in sync and is enforced at compile time

#### Cons

- Has a viral effect in that shared `State` and boxed `State` partitioning will
be propagated through the feature hierarchy
- Has a higher cognitive overhead when designing a feature having to know what
state goes where and why
- It is not always clear what is meant by shared `State` - is this reserved for
global primary types (i.e. `Appointment`) or does this get applied for any
read-only state belonging to a feature?
- Introduces boilerplate with the additional types needed, along with the
computed properties
- Introduces effort when added a new piece of shared `State` deep on the feature
hierarchy - many features need to be updated, and potentially have their state
converted to `Shared` and `Boxed`
- Introduces a design smell since the child feature needs to organize its
`State` to solve a problem for the parent feature - even though at a local scope
a child feature does not know about or care which parent(s) feature is using it

## Synchronize with a Dependency

- A feature never exposes shared `State` on the initializer `State` so parent
features are not responsible for passing the value in
- The child feature is now responsible for keep the shared `State` up to date by
having logic in its reducer
- The owner of the shared `State` uses a dependency to write new values
- The consumer uses the same dependency to observe values

### Example

```swift
struct ParentState {
  var someValue: A
  var someSharedValue: B
  var someChild: ChildState
  var someOtherChild: OtherChildState
}

struct ChildState {
    var someSharedValue: B
    var someChildValue: C
}

struct OtherChildState {
    var someSharedValue: B
    var someOtherChildValue: D
}


// Parent's reducer
func core(into state: inout State, action: Action) -> EffectTask<Action> {
    case .sharedValueUpdated(let newValue):
      await sharedStateClient.write(newValue)
      return .none
}

// Child's reducer
func core(into state: inout State, action: Action) -> EffectTask<Action> {
    case .task:
      return .run{ send in
        for await newValue in sharedStateClient.observe() {
            await send(.valueUpdated(newValue))
        }
      }

    case .valueUpdated(newValue):
      state.someSharedValue = newValue
      return .none
}
```

### Consequences

#### Pros

- Although the compile time guarantee is traded for a runtime error (i.e. if a
child reducer does not fetch the value) any bugs are local only to that reducer.
This is an improvement over the "synchronize not share" approach
- This is only partially viral: only feature nodes in the feature hierarchy that
make use of the shared value need to observe values and have the shared value
defined on their `State`. This is not true all other approaches.
- State retains a simple structure

#### Cons

- Compile time safety is traded for runtime error (i.e. owner forgets to write
an updated value, consumer does not listen)
- Internal initializer is needed for view tests to allow full setting of state
- The difference between using a shared state client vs using the real client in
each feature is subtle and could be a point of confusion

## Use the Client Directly

- Each feature is responsible for fetching its own shared `State` through a
client
- Rather than use a dedicated shared state client, the "real" client is used
instead

### Example

```swift
struct ParentState {
  var someValue: A
  var someSharedValue: B
  var someChild: ChildState
  var someOtherChild: OtherChildState
}

struct ChildState {
    var someSharedValue: B
    var someChildValue: C
}

struct OtherChildState {
    var someSharedValue: B
    var someOtherChildValue: D
}

// Child's reducer
func core(into state: inout State, action: Action) -> EffectTask<Action> {
    case .task:
      return .run{ send in
        for await newValue in realClient.observe() {
            await send(.valueUpdated(newValue))
        }
      }

    case .valueUpdated(newValue):
      state.someSharedValue = newValue
      return .none
}
```

### Consequences

#### Pros

- Same as using the shared `State` client

#### Cons

- State is never synchronized explicitly - if the client returns random values
(as an example) then each feature will have a different value and the single
source of truth is lost
- Potential performance bottleneck: the shared state client is lightweight
whereas interacting with the real client involves reaching out into the
environment: databases, network requests, etc
