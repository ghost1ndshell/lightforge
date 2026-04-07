import {
  createRootRoute,
  createRoute,
  createRouter,
  Outlet,
} from "@tanstack/react-router";
import { HomePage } from "../routes/home";
import { AuthCallbackPage } from "../routes/auth-callback";
import { CharactersPage } from "../routes/characters";
import { CharacterDetailPage } from "../routes/character-detail";

const rootRoute = createRootRoute({
  component: Outlet,
});

const homeRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: "/",
  component: HomePage,
});

const authCallbackRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: "/auth/bnet/callback",
  component: AuthCallbackPage,
});

const charactersRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: "/characters",
  component: CharactersPage,
});

const characterDetailRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: "/characters/$region/$realm/$name",
  component: CharacterDetailPage,
});

const routeTree = rootRoute.addChildren([
  homeRoute,
  authCallbackRoute,
  charactersRoute,
  characterDetailRoute,
]);

export const router = createRouter({ routeTree });
