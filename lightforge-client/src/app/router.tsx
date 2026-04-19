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
import { CharacterGearingPage } from "../routes/character-gearing";

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

const characterGearingRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: "/characters/$region/$realm/$name/forge-path/$mode",
  component: CharacterGearingPage,
});

const routeTree = rootRoute.addChildren([
  homeRoute,
  authCallbackRoute,
  charactersRoute,
  characterDetailRoute,
  characterGearingRoute,
]);

export const router = createRouter({ routeTree });
