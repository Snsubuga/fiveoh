function checkAll(checkBox) {
	var inputElements = document.getElementsByTagName("input");
	for (var i = 0; i < inputElements.length; i++) {
		if (inputElements[i].type == 'checkbox') {
			inputElements[i].checked = checkBox.checked;
		}
	}
}