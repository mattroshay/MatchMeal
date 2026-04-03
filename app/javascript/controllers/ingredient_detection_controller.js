import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "imageUpload",
    "detectButton",
    "ingredientCheckbox",
    "generateButton",
    "newIngredientInput",
    "manualInput",
    "uploadButton",
    "imagePreview",
    "previewImg",
    "fileName"
  ];

  connect() {
    this.checkButtonStates();
    this.checkGenerateButtonState();
  }

  checkButtonStates() {
    if (!this.hasDetectButtonTarget) {
      return;
    }

    const hasImage =
      this.hasImageUploadTarget && this.imageUploadTarget.files.length > 0;
    const hasManual =
      this.hasManualInputTarget &&
      this.manualInputTarget.value.trim().length > 0;

    this.detectButtonTarget.disabled = !(hasImage || hasManual);
  }

  imageSelected() {
    const file = this.imageUploadTarget.files[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = (e) => {
        this.previewImgTarget.src = e.target.result;
        this.fileNameTarget.textContent = file.name;
        this.uploadButtonTarget.classList.add("d-none");
        this.imagePreviewTarget.classList.remove("d-none");
      };
      reader.readAsDataURL(file);
    }
    this.checkButtonStates();
  }

  formSubmitting() {
    this.detectButtonTarget.disabled = true;
    this.detectButtonTarget.innerHTML =
      '<span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>Finding ingredients...';
  }

  manualInputChanged() {
    this.checkButtonStates();
  }

  ingredientCheckboxChanged() {
    this.checkGenerateButtonState();
  }

  checkGenerateButtonState() {
    if (this.hasGenerateButtonTarget) {
      const checkedIngredients = this.ingredientCheckboxTargets.filter(
        (checkbox) => checkbox.checked
      );
      this.generateButtonTarget.disabled = checkedIngredients.length === 0;
    }
  }

  removeIngredient(event) {
    const listItem = event.currentTarget.closest(".list-group-item");
    listItem.remove();

    this.updateDetectedIngredients();
    this.checkGenerateButtonState();
  }

  addIngredient() {
    const newIngredient = this.newIngredientInputTarget.value.trim();

    if (newIngredient) {
      const listGroup = this.element.querySelector(".list-group");
      const index = this.ingredientCheckboxTargets.length;

      // Create new list item dynamically
      const listItem = document.createElement("div");
      listItem.className =
        "list-group-item py-3 px-3 rounded-pill shadow-sm border d-flex align-items-center justify-content-between mb-2";

      listItem.innerHTML = `
        <label class="d-flex align-items-center flex-grow-1">
          <input type="checkbox" 
                 name="selected_ingredients[]" 
                 value="${newIngredient}" 
                 id="ingredient_${index}" 
                 class="form-check-input me-3"
                 data-ingredient-detection-target="ingredientCheckbox"
                 checked>
          <span class="text-capitalize fs-5 fw-bold">${newIngredient}</span>
        </label>
        <button type="button" 
                class="btn btn-outline-danger btn-sm rounded-pill shadow-sm" 
                data-action="click->ingredient-detection#removeIngredient"
                data-ingredient="${newIngredient}"
                data-index="${index}">
          <i class="fa-regular fa-trash-can"></i>
        </button>
      `;

      listGroup.appendChild(listItem);

      // Clear input field
      this.newIngredientInputTarget.value = "";

      this.checkGenerateButtonState();
    }
  }

  updateDetectedIngredients() {
    const remainingIngredients = Array.from(
      this.element.querySelectorAll('input[name="selected_ingredients[]"]')
    )
      .map((input) => input.value)
      .join(",");
  }
}
