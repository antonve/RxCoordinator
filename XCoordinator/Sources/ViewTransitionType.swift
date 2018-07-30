//
//  ViewTransitionType.swift
//  XCoordinator
//
//  Created by Paul Kraft on 27.07.18.
//

internal enum ViewTransitionType {
    indirect case animated(ViewTransitionType, animation: Animation)
    case present(Presentable)
    case embed(Presentable, `in`: Container)
    case registerPeek(container: Container, transitionGenerator: () -> ViewTransition)
    case dismiss
    case none
    case multiple([ViewTransitionType])

    // MARK: - Computed properties

    public var presentable: Presentable? {
        switch self {
        case .present(let presentable):
            return presentable
        case .embed(let presentable, _):
            return presentable
        case .dismiss, .none, .multiple:
            return nil
        case .registerPeek(_, let popTransition):
            return popTransition().presentable
        case .animated(let transition, _):
            return transition.presentable
        }
    }

    // MARK: - Methods

    public func perform<C: Coordinator>(options: TransitionOptions, animation: Animation?, coordinator: C, completion: PresentationHandler?) where ViewTransition == C.TransitionType {
        switch self {
        case .multiple(let transitions):
            guard let first = transitions.first else {
                completion?()
                return
            }
            first.perform(options: options, animation: animation, coordinator: coordinator, completion: {
                let newTransitions = Array(transitions[1...])
                coordinator.performTransition(.multiple(newTransitions), with: options, completion: completion)
            })
        case .animated(let transition, let animation):
            return transition.perform(options: options, animation: animation, coordinator: coordinator, completion: completion)
        case .present(let presentable):
            presentable.presented(from: coordinator)
            return coordinator.present(presentable.viewController, with: options, animation: animation, completion: completion)
        case .embed(let presentable, let container):
            presentable.presented(from: coordinator)
            return coordinator.embed(presentable.viewController, in: container, with: options, completion: completion)
        case .registerPeek(let source, let transitionGenerator):
            return coordinator.registerPeek(from: source.view, transitionGenerator: transitionGenerator, completion: completion)
        case .dismiss:
            return coordinator.dismiss(with: options, animation: animation, completion: completion)
        case .none:
            return
        }
    }
}