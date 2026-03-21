import SwiftUI
import SwiftData
import os

struct NewRecipeSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var createdRecipe: PaintRecipe?
    @State private var showingEditor = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("New Recipe")
                    .font(.title3.bold())
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(20)

            Divider().background(Color.wmBorder)

            Form {
                Section {
                    LabeledContent("Recipe Name") {
                        TextField("e.g. Space Marine Armour", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }
                } footer: {
                    Text("Give your recipe a descriptive name. You can add steps after creating it.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let msg = errorMessage {
                    Section {
                        Text(msg).foregroundStyle(.red).font(.caption)
                    }
                }
            }
            .formStyle(.grouped)

            Divider().background(Color.wmBorder)

            HStack {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                Spacer()
                Button("Create & Add Steps") {
                    createRecipe()
                }
                .buttonStyle(.borderedProminent)
                .tint(.wmPrimary)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(20)
        }
        .frame(width: 400, height: 280)
        .background(Color.wmBackground)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingEditor) {
            if let recipe = createdRecipe {
                RecipeStepEditorView(recipe: recipe) {
                    dismiss()
                }
            }
        }
    }

    private func createRecipe() {
        do {
            let recipe = try RecipeService.createRecipe(
                name: name.trimmingCharacters(in: .whitespaces),
                projectId: nil,
                context: modelContext
            )
            createdRecipe = recipe
            showingEditor = true
        } catch {
            errorMessage = error.localizedDescription
            Logger.recipe.error("Failed to create recipe: \(error)")
        }
    }
}
