//
//  AppFlow.swift
//  RxFlowDemo
//
//  Created by Thibault Wittemberg on 18-02-08.
//  Copyright © 2018 RxSwiftCommunity. All rights reserved.
//

import Foundation
import UIKit
import RxFlow

class AppFlow: Flow {
    var root: Presentable {
        return self.rootWindow
    }

    private let rootWindow: UIWindow
    private let services: AppServices

    init(withWindow window: UIWindow, andServices services: AppServices) {
        self.rootWindow = window
        self.services = services
    }

    deinit {
        print("\(type(of: self)): \(#function)")
    }

    func navigate(to step: Step) -> FlowContributors {
        guard let step = step as? DemoStep else { return FlowContributors.none }

        switch step {
        case .onboarding, .logout:
            return navigationToOnboardingScreen()
        case .onboardingIsComplete, .dashboard:
            return navigationToDashboardScreen()
        default:
            return FlowContributors.none
        }
    }

    private func navigationToOnboardingScreen() -> FlowContributors {

        if let rootViewController = self.rootWindow.rootViewController {
            rootViewController.dismiss(animated: false)
        }

        let onboardingFlow = OnboardingFlow(withServices: self.services)
        Flows.whenReady(flow1: onboardingFlow) { [unowned self] (root) in
            self.rootWindow.rootViewController = root
        }

        return .one(flowItem: FlowContributor(nextPresentable: onboardingFlow,
                                              nextStepper: OneStepper(withSingleStep: DemoStep.login)))
    }

    private func navigationToDashboardScreen() -> FlowContributors {
        let dashboardFlow = DashboardFlow(withServices: self.services)

        Flows.whenReady(flow1: dashboardFlow) { [unowned self] (root) in
            self.rootWindow.rootViewController = root
        }

        return .one(flowItem: FlowContributor(nextPresentable: dashboardFlow,
                                              nextStepper: OneStepper(withSingleStep: DemoStep.dashboard)))
    }

}

class AppStepper: Stepper {
    init(withServices services: AppServices) {
        if services.preferencesService.isOnboarded() {
            self.step.accept(DemoStep.dashboard)
        } else {
            self.step.accept(DemoStep.onboarding)
        }
    }
}
