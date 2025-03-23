document.addEventListener("DOMContentLoaded", () => {
  const menuButton = document.querySelector("[data-menu-button]");
  const closeButton = document.querySelector("[data-menu-close]");
  const mobileMenu = document.querySelector("[data-mobile-menu]");

  if (menuButton && closeButton && mobileMenu) {
    menuButton.addEventListener("click", () => {
      mobileMenu.classList.remove("hidden");
      setTimeout(() => {
        mobileMenu.classList.remove("translate-x-full");
      }, 10);
    });

    closeButton.addEventListener("click", () => {
      mobileMenu.classList.add("translate-x-full");
      setTimeout(() => {
        mobileMenu.classList.add("hidden");
      }, 300);
    });
  }
}); 