#[cfg(feature = "server")]
use axum::{
    extract::{Query, State},
    http::StatusCode,
    response::Redirect,
};
#[cfg(feature = "server")]
use base64::{engine::general_purpose, Engine as _};
#[cfg(feature = "server")]
use openidconnect::{
    core::{CoreClient, CoreProviderMetadata, CoreResponseType},
    reqwest::async_http_client,
    AuthenticationFlow, AuthorizationCode, ClientId, ClientSecret, CsrfToken, IssuerUrl, Nonce,
    OAuth2TokenResponse, RedirectUrl, Scope, TokenResponse,
};
#[cfg(feature = "server")]
use serde::{Deserialize, Serialize};
#[cfg(feature = "server")]
use std::sync::Arc;
#[cfg(feature = "server")]
use tower_cookies::{Cookie, Cookies, Key};

#[cfg(feature = "server")]
#[derive(Clone)]
pub struct AuthState {
    pub oidc_client: Arc<CoreClient>,
    pub cookie_key: Key,
}

#[cfg(feature = "server")]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Session {
    pub access_token: String,
    pub id_token: String,
    pub user_info: UserInfo,
}

#[cfg(feature = "server")]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserInfo {
    pub sub: String,
    pub email: Option<String>,
    pub name: Option<String>,
    pub preferred_username: Option<String>,
}

#[cfg(feature = "server")]
const SESSION_COOKIE_NAME: &str = "session";

#[cfg(feature = "server")]
pub async fn init_auth_state() -> AuthState {
    // Get configuration from environment variables
    let issuer_url = IssuerUrl::new(
        std::env::var("ZITADEL_ISSUER_URL").expect("ZITADEL_ISSUER_URL must be set"),
    )
    .expect("Invalid ZITADEL_ISSUER_URL");

    let client_id =
        ClientId::new(std::env::var("ZITADEL_CLIENT_ID").expect("ZITADEL_CLIENT_ID must be set"));

    let client_secret = ClientSecret::new(
        std::env::var("ZITADEL_CLIENT_SECRET").expect("ZITADEL_CLIENT_SECRET must be set"),
    );

    let redirect_url = RedirectUrl::new(
        std::env::var("ZITADEL_REDIRECT_URL")
            .unwrap_or_else(|_| "http://localhost:8080/auth/callback".to_string()),
    )
    .expect("Invalid ZITADEL_REDIRECT_URL");

    // Discover the provider metadata
    let provider_metadata =
        CoreProviderMetadata::discover_async(issuer_url.clone(), async_http_client)
            .await
            .expect("Failed to discover provider metadata");

    // Create the OIDC client
    let oidc_client =
        CoreClient::from_provider_metadata(provider_metadata, client_id, Some(client_secret))
            .set_redirect_uri(redirect_url);

    // Generate or load cookie key for signing
    // In production, set COOKIE_SECRET_KEY environment variable (32 bytes base64 encoded)
    let cookie_key = if let Ok(key_str) = std::env::var("COOKIE_SECRET_KEY") {
        let key_bytes = general_purpose::STANDARD
            .decode(key_str)
            .expect("COOKIE_SECRET_KEY must be valid base64 encoded 32 bytes");
        if key_bytes.len() != 32 {
            panic!("COOKIE_SECRET_KEY must be exactly 32 bytes");
        }
        Key::from(&key_bytes)
    } else {
        // Generate a random key for development
        Key::generate()
    };

    AuthState {
        oidc_client: Arc::new(oidc_client),
        cookie_key,
    }
}

#[cfg(feature = "server")]
pub fn get_session(cookies: &Cookies, cookie_key: &Key) -> Option<Session> {
    cookies
        .private(cookie_key)
        .get(SESSION_COOKIE_NAME)
        .and_then(|cookie| serde_json::from_str::<Session>(cookie.value()).ok())
}

#[cfg(feature = "server")]
pub fn set_session(cookies: &Cookies, cookie_key: &Key, session: Session) {
    let cookie_value = serde_json::to_string(&session).expect("Failed to serialize session");
    let mut cookie = Cookie::new(SESSION_COOKIE_NAME, cookie_value);
    cookie.set_path("/");
    cookie.set_http_only(true);
    cookie.set_secure(false); // Set to true in production with HTTPS
                              // SameSite setting omitted due to version compatibility
    cookies.private(cookie_key).add(cookie);
}

#[cfg(feature = "server")]
pub fn clear_session(cookies: &Cookies, cookie_key: &Key) {
    let cookie = Cookie::build((SESSION_COOKIE_NAME, "")).path("/").build();
    cookies.private(cookie_key).remove(cookie);
}

#[cfg(feature = "server")]
pub async fn login_handler(
    State(auth_state): State<AuthState>,
    cookies: Cookies,
) -> Result<Redirect, StatusCode> {
    // Generate a CSRF token and nonce
    let csrf_token = CsrfToken::new_random();
    let csrf_token_secret = csrf_token.secret().clone();
    let nonce = Nonce::new_random();
    let csrf_token_for_flow = csrf_token.clone();
    let nonce_for_flow = nonce.clone();

    let (auth_url, _, _) = auth_state
        .oidc_client
        .authorize_url(
            AuthenticationFlow::<CoreResponseType>::AuthorizationCode,
            move || csrf_token_for_flow.clone(),
            move || nonce_for_flow.clone(),
        )
        .add_scope(Scope::new("openid".to_string()))
        .add_scope(Scope::new("profile".to_string()))
        .add_scope(Scope::new("email".to_string()))
        .url();

    // Store CSRF token in cookie for verification in callback
    let mut csrf_cookie = Cookie::new("csrf_token", csrf_token_secret);
    csrf_cookie.set_path("/");
    csrf_cookie.set_http_only(true);
    csrf_cookie.set_secure(false);
    // SameSite setting omitted due to version compatibility
    cookies.add(csrf_cookie);

    Ok(Redirect::to(auth_url.as_str()))
}

// ava was here
// Patrick loves me

#[cfg(feature = "server")]
#[derive(Deserialize)]
pub struct CallbackQuery {
    code: Option<String>,
    state: Option<String>,
    error: Option<String>,
}

#[cfg(feature = "server")]
pub async fn callback_handler(
    State(auth_state): State<AuthState>,
    cookies: Cookies,
    Query(params): Query<CallbackQuery>,
) -> Result<Redirect, StatusCode> {
    // Check for errors from Zitadel
    if let Some(error) = params.error {
        eprintln!("OIDC error: {}", error);
        return Ok(Redirect::to("/login?error=auth_failed"));
    }

    // Get authorization code
    let code = params.code.ok_or(StatusCode::BAD_REQUEST)?;
    let auth_code = AuthorizationCode::new(code);

    // Verify CSRF token (state parameter should match stored CSRF token)
    let state = params.state.ok_or(StatusCode::BAD_REQUEST)?;
    let stored_csrf = cookies
        .get("csrf_token")
        .map(|c| c.value().to_string())
        .ok_or(StatusCode::BAD_REQUEST)?;

    if state != stored_csrf {
        return Err(StatusCode::BAD_REQUEST);
    }

    // Exchange authorization code for tokens
    let token_response = auth_state
        .oidc_client
        .exchange_code(auth_code)
        .request_async(async_http_client)
        .await
        .map_err(|e| {
            eprintln!("Token exchange error: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    // Get user info
    let user_info_request = auth_state
        .oidc_client
        .user_info(token_response.access_token().clone(), None)
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let user_info_claims: openidconnect::core::CoreUserInfoClaims = user_info_request
        .request_async(async_http_client)
        .await
        .map_err(|e| {
            eprintln!("User info error: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    // Extract user information
    let user_info = UserInfo {
        sub: user_info_claims.subject().to_string(),
        email: user_info_claims.email().map(|e| e.to_string()),
        name: user_info_claims
            .name()
            .and_then(|n| n.get(None))
            .map(|n| n.to_string()),
        preferred_username: user_info_claims.preferred_username().map(|u| u.to_string()),
    };

    // Create session
    let session = Session {
        access_token: token_response.access_token().secret().clone(),
        id_token: token_response
            .id_token()
            .ok_or(StatusCode::INTERNAL_SERVER_ERROR)?
            .to_string(),
        user_info,
    };

    // Store session in cookie
    set_session(&cookies, &auth_state.cookie_key, session);

    // Clear CSRF token cookie
    let csrf_cookie = Cookie::build(("csrf_token", "")).path("/").build();
    cookies.remove(csrf_cookie);

    Ok(Redirect::to("/"))
}

#[cfg(feature = "server")]
pub async fn session_middleware(
    State(auth_state): State<AuthState>,
    cookies: Cookies,
    mut request: axum::extract::Request,
    next: axum::middleware::Next,
) -> axum::response::Response {
    let session = get_session(&cookies, &auth_state.cookie_key);

    request.extensions_mut().insert(session);
    let response = next.run(request).await;
    response
}

#[cfg(feature = "server")]
pub async fn me_handler(
    axum::Extension(session): axum::Extension<Option<Session>>,
) -> Result<axum::Json<UserInfo>, StatusCode> {
    let session = session.ok_or(StatusCode::UNAUTHORIZED)?;
    Ok(axum::Json(session.user_info))
}

#[cfg(feature = "server")]
pub async fn logout_handler(
    State(auth_state): State<AuthState>,
    cookies: Cookies,
) -> Result<Redirect, StatusCode> {
    clear_session(&cookies, &auth_state.cookie_key);
    Ok(Redirect::to("/"))
}
