//
//  RoutineEditViewControllerTests.swift
//  ScalePlayerTests
//
//  Created by John Shimmin on 1/13/23.
//  Copyright © 2023 shimmin. All rights reserved.
//

import CoreData
import Factory
import Mockingbird
import XCTest

@testable import ScalePlayer

class RoutineEditViewControllerTests: XCTestCase, RoutineEditResponder {
    private var editCompletedRoutine: PracticeRoutine?

    var testDataContext: CoreDataContextImpl!

    override func setUp() {
        testDataContext = CoreDataContextImpl()
    }

    func editCompleted(routine: PracticeRoutine) {}

    func create<T: NSManagedObject>() -> T {
        return testDataContext.create()
    }

    func testNewRoutineNameFlow() {
        let coordinator = mock(RoutineEditCoordinator.self)

        let vm = RoutineEditViewModel(routine: nil, coordinator: coordinator, responder: self)
        let vc = RoutineEditViewController(viewModel: vm)

        vc.viewDidLoad()

        waitForCombineSubscription()

        XCTAssert(!vc.navigationItem.rightBarButtonItem!.isEnabled)

        vm.updateName("XXX")
        waitForCombineSubscription()

        XCTAssert(vc.navigationItem.rightBarButtonItem!.isEnabled)
        XCTAssertEqual(vc.nameEditView.title, "XXX")
    }

    func testScaleTable() {
        let coordinator = mock(RoutineEditCoordinator.self)

        let routine: PracticeRoutine = create()
        let scales: [PracticeScale] = [create(), create(), create()]

        let links = scales.enumerated().map { i, scale -> RoutineScale in
            let link: RoutineScale = create()
            scale.name = "scale\(i)"
            link.scale = scale
            link.tempo = Int16(i * 10)
            return link
        }

        routine.name = "routineName"
        routine.scales = NSOrderedSet(array: links)

        let vm = RoutineEditViewModel(routine: routine, coordinator: coordinator, responder: self)
        let vc = RoutineEditViewController(viewModel: vm)

        vc.viewDidLoad()

        waitForCombineSubscription()

        XCTAssertEqual(vc.tableView.numberOfRows(inSection: 0), 3)

        _ = (0 ... 2).map { row in
            let cell = vc.tableView(
                vc.tableView,
                cellForRowAt: IndexPath(row: row, section: 0)) as! RoutineScaleTableViewCell
            XCTAssertEqual(cell.nameLabel.text, "scale\(row)")
            XCTAssertEqual(cell.tempoField.text, "\(row * 10)")
        }
    }
}
