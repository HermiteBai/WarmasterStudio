import XCTest

final class PinFlowUITests: XCTestCase {

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

    // MARK: - Paint Library

    func testPaintLibraryLoads() {
        let paintsItem = app.tables.staticTexts["Paints"]
        XCTAssertTrue(paintsItem.waitForExistence(timeout: 5),
                      "Sidebar should contain a 'Paints' navigation item")
        paintsItem.click()

        // Either a search field or the list itself should be visible
        let searchField = app.textFields.firstMatch
        let listView = app.tables.firstMatch
        let isVisible = searchField.waitForExistence(timeout: 5) || listView.waitForExistence(timeout: 5)
        XCTAssertTrue(isVisible,
                      "Paint Library should show a search bar or paint list after navigating")
    }

    // MARK: - Recipe Library

    func testRecipeLibraryLoads() {
        let recipesItem = app.tables.staticTexts["Recipes"]
        XCTAssertTrue(recipesItem.waitForExistence(timeout: 5),
                      "Sidebar should contain a 'Recipes' navigation item")
        recipesItem.click()

        // Either a list or the New Recipe button should be present
        let newRecipeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'New Recipe' OR label CONTAINS '+'")).firstMatch
        let listView = app.tables.firstMatch
        let isVisible = newRecipeButton.waitForExistence(timeout: 5) || listView.waitForExistence(timeout: 5)
        XCTAssertTrue(isVisible,
                      "Recipe Library should show a New Recipe button or recipe list after navigating")
    }

    // MARK: - Recipe Creation

    func testNewRecipeCanBeCreated() throws {
        let recipesItem = app.tables.staticTexts["Recipes"]
        XCTAssertTrue(recipesItem.waitForExistence(timeout: 5))
        recipesItem.click()

        // Tap the New Recipe button (icon-only button in the toolbar)
        let newRecipeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'New Recipe' OR label CONTAINS 'plus'")).firstMatch
        XCTAssertTrue(newRecipeButton.waitForExistence(timeout: 5),
                      "New Recipe button should be visible in the Recipe Library toolbar")
        newRecipeButton.click()

        // The New Recipe sheet should open with a text field for the recipe name
        let nameField = app.textFields.firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: 5),
                      "New Recipe sheet should contain a text field for the recipe name")
        nameField.click()
        nameField.typeText("Test Recipe UITest")

        // Tap Create or Save to confirm
        let createButton = app.buttons.matching(NSPredicate(format: "label == 'Create' OR label == 'Save' OR label == 'Add'")).firstMatch
        XCTAssertTrue(createButton.waitForExistence(timeout: 3),
                      "New Recipe sheet should have a Create/Save button")
        createButton.click()

        // The new recipe should appear in the recipe list
        XCTAssertTrue(app.staticTexts["Test Recipe UITest"].waitForExistence(timeout: 5),
                      "Newly created recipe should appear in the Recipe Library list")
    }
}
