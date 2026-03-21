import XCTest

final class KanbanBoardUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    // MARK: - App Launch

    func testAppLaunchesAndShowsKanbanBoard() {
        // The Kanban board is the home screen — it should be visible on launch
        let kanbanArea = app.scrollViews.firstMatch
        XCTAssertTrue(kanbanArea.waitForExistence(timeout: 5),
                      "Kanban board scroll view should be present on launch")
    }

    // MARK: - Sidebar Navigation

    func testSidebarContainsAllDestinations() {
        let sidebar = app.tables.firstMatch
        XCTAssertTrue(sidebar.waitForExistence(timeout: 3))

        XCTAssertTrue(sidebar.staticTexts["Kanban"].exists)
        XCTAssertTrue(sidebar.staticTexts["Progress"].exists)
        XCTAssertTrue(sidebar.staticTexts["Collections"].exists)
    }

    func testNavigatingToProgressView() {
        let progressItem = app.tables.staticTexts["Progress"]
        XCTAssertTrue(progressItem.waitForExistence(timeout: 3))
        progressItem.click()

        XCTAssertTrue(app.staticTexts["DONE"].waitForExistence(timeout: 3),
                      "Progress dashboard should show DONE hero section")
    }

    func testNavigatingToCollectionsView() {
        let collectionsItem = app.tables.staticTexts["Collections"]
        XCTAssertTrue(collectionsItem.waitForExistence(timeout: 3))
        collectionsItem.click()

        // Collections view toolbar has a + button
        let addButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'collection' OR label CONTAINS '+'")).firstMatch
        XCTAssertTrue(addButton.waitForExistence(timeout: 3),
                      "Collections view should show an add button")
    }

    // MARK: - Kanban Board Structure

    func testKanbanBoardHasDefaultColumns() {
        // Navigate to Kanban
        app.tables.staticTexts["Kanban"].click()

        // Default pipeline has 5 stages: On Sprue, Assembled, Primed, Painting, Done
        // Each column header is a static text inside the horizontal scroll area
        let expectedStages = ["On Sprue", "Assembled", "Primed", "Painting", "Done"]
        for stage in expectedStages {
            XCTAssertTrue(app.staticTexts[stage].waitForExistence(timeout: 5),
                          "Column '\(stage)' should be visible on the Kanban board")
        }
    }

    func testNewProjectButtonExists() {
        app.tables.staticTexts["Kanban"].click()

        let newProjectButton = app.buttons["New Project"]
        XCTAssertTrue(newProjectButton.waitForExistence(timeout: 3),
                      "New Project toolbar button should be present")
    }

    func testNewProjectSheetOpens() {
        app.tables.staticTexts["Kanban"].click()

        app.buttons["New Project"].click()

        // Sheet should contain a name field
        let nameField = app.textFields.firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: 3),
                      "New Project sheet should open with a text field for the project name")
    }

    func testNewProjectCreatesCardOnBoard() throws {
        app.tables.staticTexts["Kanban"].click()

        // Open new project sheet
        app.buttons["New Project"].click()

        let nameField = app.textFields.firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.click()
        nameField.typeText("Test Intercessors")

        // Tap the Create button
        let createButton = app.buttons["Create"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 3))
        createButton.click()

        // Card for "Test Intercessors" should appear in the first column ("On Sprue")
        XCTAssertTrue(app.staticTexts["Test Intercessors"].waitForExistence(timeout: 5),
                      "Newly created project card should appear on the Kanban board")
    }
}
