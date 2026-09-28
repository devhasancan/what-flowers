# WhatFlowers 🌸

An iOS application that identifies a flower from a photograph entirely on-device using CoreML and Vision, then enriches the result with live content from Wikipedia.

## 📌 Executive Summary

WhatFlowers was engineered around a deliberate constraint: the recognition itself must never leave the device. A photograph selected from the library is classified locally by a converted CoreML model across the 102 species of the Oxford 102 Flower Dataset, and only the resulting label — never the image — travels over the network. Wikipedia is then queried for the species' description and reference photograph. The result is an application that performs its core function with no account, no API key, and no server, while still delivering rich, up-to-date content.

## 🛠 Technical Architecture & Core Competencies

**On-Device Machine Learning:** Integrated Apple's `Vision` and `CoreML` frameworks through a `VNCoreMLRequest` pipeline. The inference is dispatched to a background quality-of-service queue so the classification of a full-resolution image never blocks the main thread.

**Model Conversion & Attribution:** The classifier is not a drop-in `.mlmodel`. It originates as a Caffe model trained with convolutional neural networks by Jimmie Goode on the **Oxford 102 Flower Dataset**, a research set of 102 labelled flower categories. My work was the conversion and integration: producing an `.mlpackage` with Apple's open-source Python conversion tools, wiring it into a Vision request pipeline, and reconciling its label vocabulary with an external content source. The resulting 167 MB weight file exceeds GitHub's hard limit and is version-controlled through **Git LFS**, leaving a 134-byte pointer in the repository.

**MVVM with Enforced Boundaries:** Refactored from MVC into a strict Model-View-ViewModel structure. `FlowerViewModel` owns the recognition flow and every content rule; the view controller does nothing but draw. Critically, **the view model imports no UIKit** — a constraint that makes the layer separation verifiable rather than merely claimed, and allows the entire decision layer to be tested without launching a simulator.

**Finite State Modelling:** Replaced scattered boolean flags with a `FlowerState` enum carrying associated values (`empty`, `loading`, `success(FlowerPresentation)`, `failure(message:)`). Because Swift's `switch` is exhaustive over enums, adding a new state is a compile-time error until the view handles it — a class of UI bug eliminated by the type system rather than by discipline.

**Reactive Binding & Thread Safety:** The view model's `state` property carries a `didSet` observer that marshals every transition onto the main queue exactly once, before invoking an `onStateChange` closure. Thread-correctness is therefore solved in a single location and cannot be forgotten at any call site.

**Memory Management:** `FlowerManagerDelegate` is constrained to `AnyObject` so that the delegate reference can be declared `weak`, closing a retain cycle between the controller and the networking layer. All escaping closures capture `self` weakly.

**Resilient API Integration:** Built a `FlowerManager` service that queries the Wikipedia Action API via `URLSession`, decoding a response whose page objects are keyed by dynamic page identifiers into type-safe `Codable` structures. Asynchronous image loading is guarded against race conditions: each request records the URL it is awaiting, so a slow response from a previously selected flower can never overwrite the currently displayed result.

**Unit Testing:** Covered the view model's decision layer with `XCTest`. The delegate callbacks are invoked directly to simulate Wikipedia responses, so the suite runs in milliseconds with no network dependency and deterministic results.

### Project Structure

```
WhatFlowers/
├── Application/    AppDelegate, SceneDelegate
├── Models/         FlowerData — the Wikipedia response schema
├── ViewModels/     FlowerViewModel, FlowerPresentation, FlowerState
├── Views/          FlowerViewController, storyboards
├── Services/       FlowerManager — networking and decoding
├── Extensions/     UIColor+Flower
└── Resources/      Assets, FlowerClassifier.mlpackage
WhatFlowersTests/   FlowerViewModelTests
```

## 👨‍💻 Developer Insight

The most instructive defect in this project produced no crash, no error, and no log entry — the screen simply stayed empty for certain flowers. The cause was a silent mismatch between two naming conventions: the CoreML model emits labels in Title Case ("Pink Primrose"), while Wikipedia capitalises only the first character of an article title. Rather than guessing at the scope of the problem, I swept all 102 model labels against the API and measured it: 26 of them — roughly a quarter — resolved to nothing. The fix combines lowercasing with a 13-entry mapping table for species whose common name has no article at all, restoring full coverage.

A second decision shaped the same subsystem. Wikipedia's search endpoint would have resolved every label, but it resolved them *loosely* — querying "Globe-Flower" returned the film *Killers of the Flower Moon*. A confidently wrong answer is worse than an empty one in an application whose entire purpose is identification, so the search endpoint was rejected in favour of exact title resolution plus an explicit mapping table. The application now returns either the correct species or an honest failure message, and never something in between.
