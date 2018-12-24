//
//  FlowContributor.swift
//  RxFlow
//
//  Created by Thibault Wittemberg on 17-10-09.
//  Copyright (c) RxSwiftCommunity. All rights reserved.
//

// typealias to allow compliance with older versions of RxFlow
public typealias NextFlowItem = FlowContributor

/// A FlowContributor is the result of the coordination action between a Flow and a Step (See Flow.navigate(to:) function)
/// It describes the next thing that will be presented (a Presentable) and
/// the next thing the FlowCoordinator will listen to, to have the next navigation Steps (a Stepper).
/// If a navigation action does not have to lead to a FlowContributor, it is possible to have an empty FlowContributor array
public class FlowContributor {

    /// The presentable that will be handle by the FlowCoordinator. The FlowCoordinator is not
    /// meant to display this presentable, it will only handle its "Display" status
    /// so that the associated Stepper will be listened to or not
    public let nextPresentable: Presentable

    /// The Stepper that will be handle by the FlowCoordinator. It will emit the new
    /// navigation Steps. The FlowCoordinator will listen to them only if the associated
    /// Presentable is displayed
    public let nextStepper: Stepper

    /// Initialize a new FlowContributor
    ///
    /// - Parameters:
    ///   - nextPresentable: the next presentable to be handled by the FlowCoordinator
    ///   - nextStepper: the next Steper to be handled by the FlowCoordinator
    public init(nextPresentable presentable: Presentable, nextStepper stepper: Stepper) {
        self.nextPresentable = presentable
        self.nextStepper = stepper
    }
}

// typealias to allow compliance with older versions of RxFlow
public typealias NextFlowItems = FlowContributors

/// FlowContributors reprent the next things that will trigger
/// navigation actions inside a Flow
///
/// - multiple: a Flow will trigger several FlowContributors at the same time for the same Step
/// - one: a Flow will trigger only one FlowContributor for a Step
/// - end: a Flow will trigger a special FlowContributor that represents the dismissal of this Flow
/// - triggerParentFlow: the parent Flow (if exists) will be triggered with the given Step
/// - none: no further navigation will be triggered for a Step
public enum FlowContributors {
    /// a Flow will trigger several FlowContributor at the same time for the same Step
    case multiple (flowItems: [FlowContributor])
    /// a Flow will trigger only one FlowContributor for a Step
    case one (flowItem: FlowContributor)
    /// a Flow will trigger a special FlowContributor that represents the dismissal of this Flow
    case end (withStepForParentFlow: Step)
    /// a Flow will trigger a special FlowContributor that allows to trigger a new Step for the parent Flow
    /// (same as .end but without stopping listening for child flow steppers)
    case triggerParentFlow (withStep: Step)
    /// no further navigation will be triggered for a Step
    case none
}
