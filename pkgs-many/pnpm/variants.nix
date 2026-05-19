{
  v8 = {
    version = "8.15.9";
    hash = "sha256-2qJ6C1QbxjUyP/lsLe2ZVGf/n+bWn/ZwIVWKqa2dzDY=";
  };

  v9 = {
    version = "9.15.9";
    hash = "sha256-z4anrXZEBjldQoam0J1zBxFyCsxtk+nc6ax6xNxKKKc=";
  };

  # 10.29.3 made a breaking change: https://github.com/pnpm/pnpm/issues/10601.
  # Pnpm packages that depend on electron builder must be upgraded to 26.8.2 or newer
  # otherwise a runtime error will occur when launching the application.
  v10_29_2 = {
    version = "10.29.2";
    hash = "sha256-hAL2daH0zJ1PJ7v6s1wtSi4dfrATHfA9rQlhnoZnTQw=";
  };

  v10 = {
    version = "10.33.4";
    hash = "sha256-jnDdxmSbGLw9iVzzqQjAKR6kw4A5rYcixH4Bja8enPw=";
  };

  v11 = {
    version = "11.1.2";
    hash = "sha256-v+TSssejIQVlu6YpKfnv5JPrXyRicgGhAupFFOroz4A=";
  };
}
