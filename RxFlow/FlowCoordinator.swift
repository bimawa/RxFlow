//
//  FlowCoordinator.swift
//  RxFlow
//
//  Created by Thibault Wittemberg on 2018-12-19.
//  Copyright © 2018 RxSwiftCommunity. All rights reserved.
//
import RxSwift
import RxCocoa

// typealias to allow compliance with older versions of RxFlow
public typealias Coordinator = FlowCoordinator

public final class FlowCoordinator: NSObject {
    private let disposeBag = DisposeBag()

    // FlowCoordinator relations (father/children)
    private var childFlowCoordinators = [String: FlowCoordinator]()
    private weak var parentFlowCoordinator: FlowCoordinator? {
        didSet {
            if let parentFlowCoordinator = self.parentFlowCoordinator {
                self.willNavigateRelay.bind(to: parentFlowCoordinator.willNavigateRelay).disposed(by: self.disposeBag)
                self.didNavigateRelay.bind(to: parentFlowCoordinator.didNavigateRelay).disposed(by: self.disposeBag)
            }
        }
    }

    // Rx PublishRelays to handle steps and navigation triggering
    private let stepsRelay = PublishRelay<Step>()
    fileprivate let willNavigateRelay = PublishRelay<(Flow, Step)>()
    fileprivate let didNavigateRelay = PublishRelay<(Flow, Step)>()

    // FlowCoordinator unique identifier
    internal let identifier = UUID().uuidString

    public func coordinate (flow: Flow, with stepper: Stepper = DefaultStepper()) {

        self.stepsRelay
            .takeUntil(flow.rxDismissed.asObservable())
            .asSignal(onErrorJustReturn: NoneStep())
            .do(onNext: { [weak self] in self?.willNavigateRelay.accept((flow, $0))})
            .map { [weak flow] in return (FlowContributors: flow?.navigate(to: $0), step: $0) }
            .do(onNext: { [weak self] in self?.didNavigateRelay.accept((flow, $0.step))})
            .do(onNext: { [weak flow] _ in flow?.flowReadySubject.accept(true) })
            .filter { $0.FlowContributors != nil }
            .map { $0.FlowContributors! }
            .flatMap { [weak self] flowContributors -> Signal<FlowContributor> in
                switch flowContributors {
                case .none:
                    return Signal.empty()
                case .one(let flowItem):
                    return Signal.just(flowItem)
                case .multiple(let flowItems):
                    return Signal.from(flowItems)
                case .end(let withStepForParentFlow):
                    self?.parentFlowCoordinator?.stepsRelay.accept(withStepForParentFlow)
                    self?.childFlowCoordinators.removeAll()
                    self?.parentFlowCoordinator?.childFlowCoordinators.removeValue(forKey: self?.identifier ?? "")
                    return Signal.empty()
                case .triggerParentFlow(let withStep):
                    self?.parentFlowCoordinator?.stepsRelay.accept(withStep)
                    return Signal.empty()
                }
            }
            .do(onNext: { [weak self] flowContributor in
                if let childFlow = flowContributor.nextPresentable as? Flow {
                    let childFlowCoordinator = FlowCoordinator()
                    childFlowCoordinator.parentFlowCoordinator = self
                    childFlowCoordinator.coordinate(flow: childFlow, with: flowContributor.nextStepper)
                    self?.childFlowCoordinators[childFlowCoordinator.identifier] = childFlowCoordinator
                }
            })
            .filter { !($0.nextPresentable is Flow) }
            .flatMap { flowContributor -> Signal<Step> in
                return flowContributor
                    .nextStepper
                    .steps
                    .filter { !($0 is NoneStep) }
                    .takeUntil(flowContributor.nextPresentable.rxDismissed.asObservable())
                    .pausable(withPauser: flowContributor.nextPresentable.rxVisible)
                    .asSignal(onErrorJustReturn: NoneStep())
            }
            .do(onDispose: { [weak self] in
                self?.childFlowCoordinators.removeAll()
                self?.parentFlowCoordinator?.childFlowCoordinators.removeValue(forKey: self?.identifier ?? "")
            })
            .emit(to: self.stepsRelay)
            .disposed(by: self.disposeBag)

        stepper.steps
            .takeUntil(flow.rxDismissed.asObservable())
            .pausable(afterCount: 1, withPauser: flow.rxVisible)
            .bind(to: self.stepsRelay)
            .disposed(by: self.disposeBag)
    }
}

public extension Reactive where Base: FlowCoordinator {
    public var willNavigate: Observable<(Flow, Step)> {
        return self.base.willNavigateRelay.asObservable()
    }

    public var didNavigate: Observable<(Flow, Step)> {
        return self.base.didNavigateRelay.asObservable()
    }
}
