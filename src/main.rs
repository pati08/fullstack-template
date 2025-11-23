// The dioxus prelude contains a ton of common items used in dioxus apps. It's a good idea to import wherever you
// need dioxus
use dioxus::prelude::*;
use serde::{Deserialize, Serialize};

use views::{Home, Login, ManageAccount, Navbar};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ClientUserInfo {
    pub email: Option<String>,
    pub name: Option<String>,
    pub preferred_username: Option<String>,
}
#[cfg(feature = "server")]
impl From<auth::UserInfo> for ClientUserInfo {
    fn from(value: auth::UserInfo) -> Self {
        Self {
            email: value.email,
            name: value.name,
            preferred_username: value.preferred_username,
        }
    }
}

/// Define an auth module for OIDC authentication
#[cfg(feature = "server")]
mod auth;
/// Define a components module that contains all shared components for our app.
mod components;
/// Define a views module that contains the UI for all Layouts and Routes for our app.
mod views;

/// The Route enum is used to define the structure of internal routes in our app. All route enums need to derive
/// the [`Routable`] trait, which provides the necessary methods for the router to work.
/// 
/// Each variant represents a different URL pattern that can be matched by the router. If that pattern is matched,
/// the components for that route will be rendered.
#[derive(Debug, Clone, Routable, PartialEq)]
#[rustfmt::skip]
enum Route {
    // The layout attribute defines a wrapper for all routes under the layout. Layouts are great for wrapping
    // many routes with a common UI like a navbar.
    #[layout(Navbar)]
        // The route attribute defines the URL pattern that a specific route matches. If that pattern matches the URL,
        // the component for that route will be rendered. The component name that is rendered defaults to the variant name.
        #[route("/")]
        Home {},
        #[route("/login")]
        Login {},
        #[route("/manage-account")]
        ManageAccount {},

        #[route("/:..segments")]
        NotFound { segments: Vec<String> },
}

#[component]
fn NotFound(segments: Vec<String>) -> Element {
    rsx! {
        "Page " {segments.join("/")} " does not exist"
    }
}

// We can import assets in dioxus with the `asset!` macro. This macro takes a path to an asset relative to the crate root.
// The macro returns an `Asset` type that will display as the path to the asset in the browser or a local path in desktop bundles.
const FAVICON: Asset = asset!("/assets/favicon.ico");
// The asset macro also minifies some assets like CSS and JS to make bundled smaller
const MAIN_CSS: Asset = asset!("/assets/styling/main.css");

fn main() {
    #[cfg(feature = "web")]
    // Hydrate the application on the client
    dioxus::launch(App);

    // Launch axum on the server
    #[cfg(feature = "server")]
    {
        tokio::runtime::Runtime::new()
            .unwrap()
            .block_on(async move {
                launch_server(App).await;
            });
    }
}
#[cfg(feature = "server")]
async fn launch_server(component: fn() -> Element) {
    use axum::routing::get;
    use std::net::{IpAddr, Ipv4Addr, SocketAddr};
    use tower_cookies::CookieManagerLayer;

    #[cfg(debug_assertions)]
    {
        let _ = dotenvy::dotenv().inspect_err(|_e| eprintln!(".env file not found"));
    }

    // Initialize auth state
    let auth_state = auth::init_auth_state().await;

    // Get the address the server should run on. If the CLI is running, the CLI proxies fullstack into the main address
    // and we use the generated address the CLI gives us
    let ip =
        dioxus::cli_config::server_ip().unwrap_or_else(|| IpAddr::V4(Ipv4Addr::new(127, 0, 0, 1)));
    let port = dioxus::cli_config::server_port().unwrap_or(8080);
    let address = SocketAddr::new(ip, port);
    let listener = tokio::net::TcpListener::bind(address).await.unwrap();

    let dioxus_router = axum::Router::new()
        // serve_dioxus_application adds routes to server side render the application, serve static assets, and register server functions
        .serve_dioxus_application(ServeConfig::default(), component);

    let auth_router = axum::Router::new()
        // Auth routes
        .route("/auth/login", get(auth::login_handler))
        .route("/auth/callback", get(auth::callback_handler))
        .route("/auth/me", get(auth::me_handler))
        .route("/auth/logout", get(auth::logout_handler));

    let router = auth_router
        .with_state(auth_state.clone())
        .merge(dioxus_router)
        .layer(axum::middleware::from_fn_with_state(
            auth_state,
            auth::session_middleware,
        ))
        .layer(CookieManagerLayer::new());

    axum::serve(listener, router).await.unwrap();
}

/// App is the main component of our app. Components are the building blocks of dioxus apps. Each component is a function
/// that takes some props and returns an Element. In this case, App takes no props because it is the root of our app.
///
/// Components should be annotated with `#[component]` to support props, better error messages, and autocomplete
#[component]
fn App() -> Element {
    // The `rsx!` macro lets us define HTML inside of rust. It expands to an Element with all of our HTML inside.
    rsx! {
        // In addition to element and text (which we will see later), rsx can contain other components. In this case,
        // we are using the `document::Link` component to add a link to our favicon and main CSS file into the head of our app.
        document::Link { rel: "icon", href: FAVICON }
        document::Link { rel: "stylesheet", href: MAIN_CSS }

        // The router component renders the route enum we defined above. It will handle synchronization of the URL and render
        // the layouts and components for the active route.
        Router::<Route> {}
    }
}
