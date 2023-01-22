//
//  RoutineEditViewModelTests.swift
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

class RoutineEditViewModelTests: XCTestCase, RoutineEditResponder {
    private var editCompletedRoutine: PracticeRoutine?

    var testDataContext: CoreDataContextImpl!

    override func setUp() {
        testDataContext = CoreDataContextImpl()
        editCompletedRoutine = nil
    }

    func editCompleted(routine: PracticeRoutine) {
        editCompletedRoutine = routine
    }

    func create<T: NSManagedObject>() -> T {
        return testDataContext.create()
    }

    func testNewRoutineNameFlow() {
        let coordinator = mock(RoutineEditCoordinator.self)
        let coreDataContext = mock(CoreDataContext.self)
        Container.coreDataContext.register { coreDataContext }

        let routine: PracticeRoutine = create()
        given(coreDataContext.create()).willReturn(routine)

        let vm = RoutineEditViewModel(routine: nil, coordinator: coordinator, responder: self)
        XCTAssert(vm.name.isEmpty)
        XCTAssertEqual(vm.title, RoutineEditViewModel.newRoutineTitle)

        vm.updateName("XXX")
        XCTAssertEqual(vm.name, "XXX")
        XCTAssertEqual(vm.title, "XXX")
        verify(coreDataContext.save()).wasNeverCalled()

        vm.save()
        XCTAssert(vm.editSessionComplete)
        XCTAssertEqual(routine.name, "XXX")

        verify(coreDataContext.save()).wasCalled()
        XCTAssert(editCompletedRoutine === routine)
    }

    func testValidateNameDuplicate() {
        let coordinator = mock(RoutineEditCoordinator.self)

        let routineDataStore = mock(RoutineDataStore.self)
        Container.routineDataStore.register { routineDataStore }

        given(routineDataStore.isDuplicate(name: any(), routine: any())).willReturn(true)
        let vm = RoutineEditViewModel(routine: nil, coordinator: coordinator, responder: self)
        let result = vm.validateName("foo")
        XCTAssertEqual(
            result,
            SingleValueEditor.ValidationResult.invalid(message: "Name already exists"))
    }

    func testValidateNameUnique() {
        let coordinator = mock(RoutineEditCoordinator.self)

        let routineDataStore = mock(RoutineDataStore.self)
        Container.routineDataStore.register { routineDataStore }

        given(routineDataStore.isDuplicate(name: any(), routine: any())).willReturn(false)
        let vm = RoutineEditViewModel(routine: nil, coordinator: coordinator, responder: self)
        let result = vm.validateName("foo")
        XCTAssertEqual(result, SingleValueEditor.ValidationResult.valid)
    }

    func setupViewModelAndLinks() -> (RoutineEditViewModel, [RoutineScale]) {
        let coordinator = mock(RoutineEditCoordinator.self)

        let vm = RoutineEditViewModel(routine: nil, coordinator: coordinator, responder: self)
        let coreDataContext = mock(CoreDataContext.self)
        Container.coreDataContext.register { coreDataContext }

        let links: [RoutineScale] = [create(), create(), create()]
        given(coreDataContext.create())
            .willReturn(links[0])
            .willReturn(links[1])
            .willReturn(links[2])

        let scales: [PracticeScale] = [create(), create(), create()]
        vm.scalesSelected(scales: scales)
        XCTAssertEqual(vm.scales, links)

        return (vm, links)
    }

    func testRemoveScaleAtIndex() {
        let (vm, links) = setupViewModelAndLinks()

        vm.removeScaleAtIndex(1)
        XCTAssertEqual(vm.scales, [links[0], links[2]])
    }

    func testMoveScaleFromIndex() {
        let (vm, links) = setupViewModelAndLinks()

        vm.moveScaleFromIndex(0, to: 2)
        XCTAssertEqual(vm.scales, [links[1], links[2], links[0]])
    }
}
