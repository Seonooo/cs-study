// Theme toggle — persist in localStorage
(function () {
  const KEY = "cs-study-theme";
  const saved = localStorage.getItem(KEY);
  if (saved === "light") document.documentElement.setAttribute("data-theme", "light");

  window.toggleTheme = function () {
    const cur = document.documentElement.getAttribute("data-theme");
    if (cur === "light") {
      document.documentElement.removeAttribute("data-theme");
      localStorage.setItem(KEY, "dark");
    } else {
      document.documentElement.setAttribute("data-theme", "light");
      localStorage.setItem(KEY, "light");
    }
  };
})();
