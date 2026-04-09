export type NavItem = { title: string; href: string };
export type NavGroup = { title: string; children: NavItem[] };
export type NavEntry = NavItem | NavGroup;

export function isNavGroup(entry: NavEntry): entry is NavGroup {
  return "children" in entry;
}

export const siteConfig = {
  name: "ForgeBackgroundTasks",
  description: "BGTaskScheduler registration, scheduling, and dispatch for iOS.",
  github: "https://github.com/stefanprojchev/ForgeBackgroundTasks",
  nav: {
    docs: [
      { title: "Getting Started", href: "docs/getting-started" },
      {
        title: "Components",
        children: [
          { title: "BackgroundTask Protocol", href: "docs/background-task" },
          { title: "BackgroundTaskSchedule", href: "docs/schedule" },
          { title: "BackgroundTaskContext", href: "docs/context" },
          { title: "BackgroundTaskRegistry", href: "docs/registry" },
        ],
      },
    ] as NavEntry[],
    examples: [
      { title: "Basic Setup", href: "examples/basic-setup" },
      { title: "With ForgeInject", href: "examples/with-forge-inject" },
    ] as NavEntry[],
  },
};

export const proseClasses = "prose prose-neutral dark:prose-invert prose-headings:font-semibold prose-headings:tracking-tight prose-h1:text-2xl prose-h1:mb-2 prose-h2:mt-10 prose-h2:text-lg prose-h2:border-b prose-h2:border-border/60 prose-h2:pb-2 prose-h3:text-base prose-p:text-[15px] prose-p:leading-relaxed prose-code:rounded prose-code:bg-muted prose-code:px-1.5 prose-code:py-0.5 prose-code:font-mono prose-code:text-[13px] prose-code:font-normal prose-code:before:content-none prose-code:after:content-none prose-pre:bg-transparent prose-pre:p-0 prose-a:text-orange-600 prose-a:no-underline hover:prose-a:underline dark:prose-a:text-amber-400 max-w-none";

/** Resolve a nav href to a full path including base URL */
export function resolveHref(href: string): string {
  const base = import.meta.env.BASE_URL.replace(/\/$/, "");
  return `${base}/${href}`;
}
