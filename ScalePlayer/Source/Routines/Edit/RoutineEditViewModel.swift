//
//  RoutineEditViewModel.swift
//  ScalePlayer
//
//  Created by John Shimmin on 12/19/22.
//  Copyright © 2022 shimmin. All rights reserved.
//

import Combine
import Factory

protocol RoutineEditResponder {
    func editCompleted(routine: PracticeRoutine)
}

class RoutineEditViewModel {
    static let newRoutineTitle = "<New Routine>"

    @PublishedOnMain
    private(set) var name = "" {
        didSet { title = name }
    }

    @PublishedOnMain
    private(set) var scales: [RoutineScale] = []

    @PublishedOnMain
    private(set) var editSessionComplete = false

    @PublishedOnMain
    var title: String = newRoutineTitle

    private weak var coordinator: RoutineEditCoordinator?

    @Injected(Container.coreDataContext)
    private var coreDataContext: CoreDataContext

    @Injected(Container.routineDataStore)
    private var routineDataStore: RoutineDataStore

    private var routine: PracticeRoutine?
    private var responder: RoutineEditResponder
    private var routineUpdated = false

    init(routine: PracticeRoutine?, coordinator: RoutineEditCoordinator, responder: RoutineEditResponder) {

        self.routine = routine
        self.coordinator = coordinator
        self.responder = responder

        if let routine = routine {
            name = routine.name!
            title = routine.name!

            scales = routine.scalesAsArray()
        }
    }

    func moveScaleFromIndex(_ sourceIndex: Int, to destIndex: Int) {
        let movedObject = scales[sourceIndex]
        scales.remove(at: sourceIndex)
        scales.insert(movedObject, at: destIndex)
    }

    func removeScaleAtIndex(_ index: Int) {
        scales.remove(at: index)
    }

    func presentNameAlert(isCreateFlow: Bool = false) {
        if let coordinator = coordinator {
            coordinator.showNameDialog(viewModel: self, isCreateFlow: isCreateFlow, validator: { [weak self] name in
                self?.validateName(name) ?? .valid
            })
        }
    }

    func openSearch() {
        if let coordinator = coordinator {
            coordinator.showSearchDialog(responder: self)
        }
    }

    func updateName(_ updatedName: String) {
        name = updatedName
        if let routine = routine, !name.isEmpty {
            routine.name = name
            coreDataContext.save()
            routineUpdated = true
        }
    }

    func validateName(_ name: String) -> SingleValueEditor.ValidationResult {
        if routineDataStore.isDuplicate(name: name, routine: routine) {
            return .invalid(message: "Name already exists")
        } else {
            return .valid
        }
    }

    func editingCompleted() {
        if routineUpdated {
            responder.editCompleted(routine: routine!)
        }
        editSessionComplete = true
    }

    // MARK: - Actions

    func save() {
        if name.isEmpty {
            presentNameAlert(isCreateFlow: true)
            return
        }
        let routine = routine ?? Container.practiceRoutine()
        routine.name = name
        routine.scales = NSOrderedSet(array: scales)
        coreDataContext.save()

        responder.editCompleted(routine: routine)
        editSessionComplete = true
    }

    func cancel() {
        editingCompleted()
    }
}

extension RoutineEditViewModel: ScaleSearchViewModelResponder {
    // MARK: - ScaleSearchViewModelResponder

    func scalesSelected(scales: [PracticeScale]) {
        let linkedScales = scales.map { scale -> RoutineScale in
            let link = Container.routineScale()
            link.scale = scale
            return link
        }
        self.scales.append(contentsOf: linkedScales)
    }
}
