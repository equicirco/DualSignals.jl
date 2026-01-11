(() => {
  const logoImg = document.querySelector(".docs-sidebar .docs-logo img");
  if (!logoImg) {
    return;
  }

  const base = window.documenterBaseURL || ".";
  const lightSrc = `${base}/assets/logo-light.png`;
  const darkSrc = `${base}/assets/logo-dark.png`;

  const isDarkTheme = () => {
    const cls = document.documentElement.className || "";
    return (
      cls.includes("theme--documenter-dark") ||
      cls.includes("theme--catppuccin-mocha") ||
      cls.includes("theme--catppuccin-macchiato") ||
      cls.includes("theme--catppuccin-frappe")
    );
  };

  const updateLogo = () => {
    logoImg.src = isDarkTheme() ? darkSrc : lightSrc;
  };

  updateLogo();

  const observer = new MutationObserver(updateLogo);
  observer.observe(document.documentElement, { attributes: true, attributeFilter: ["class"] });
})();
