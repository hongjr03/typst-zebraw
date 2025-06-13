document.querySelectorAll(".zebraw-code-block").forEach((codeBlock) => {
  const copyButton = codeBlock.querySelector(".zebraw-code-lang");
  if (!copyButton) return;

  copyButton.style.cursor = "pointer";
  copyButton.title = "Click to copy code";

  copyButton.addEventListener("click", () => {
    const code = Array.from(codeBlock.querySelectorAll(".zebraw-code-line"))
      .map((line) => line.textContent)
      .join("\n");

    navigator.clipboard.writeText(code).catch(() => {
      const textarea = document.createElement("textarea");
      textarea.value = code;
      document.body.appendChild(textarea);
      textarea.select();
      document.execCommand("copy");
      document.body.removeChild(textarea);
    });

    const originalTitle = copyButton.title;
    copyButton.title = "Code copied!";
    setTimeout(() => (copyButton.title = originalTitle), 2000);
  });
});
