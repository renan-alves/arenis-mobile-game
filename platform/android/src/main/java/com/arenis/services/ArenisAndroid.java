package com.arenis.services;

import android.app.Activity;
import android.content.pm.ApplicationInfo;
import android.os.Build;
import android.util.Log;
import com.google.android.gms.common.api.ApiException;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.view.View;
import android.view.WindowInsets;
import android.widget.FrameLayout;
import androidx.annotation.NonNull;
import com.google.android.gms.ads.*;
import com.google.android.gms.ads.interstitial.InterstitialAd;
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback;
import com.google.android.ump.*;
import com.google.android.gms.games.PlayGames;
import com.google.android.gms.games.PlayGamesSdk;
import com.google.android.gms.games.SnapshotsClient;
import com.google.android.gms.games.snapshot.Snapshot;
import com.google.android.gms.games.snapshot.SnapshotMetadataChange;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;
import java.nio.charset.StandardCharsets;
import java.util.HashSet;
import java.util.Set;

/** Thin SDK bridge. Game rules, scoring, cadence and merges stay in GDScript. */
public final class ArenisAndroid extends GodotPlugin {
    private FrameLayout overlay;
    private AdView banner;
    private ConsentInformation consent;
    private InterstitialAd interstitial;
    private boolean adsInitialized, adsInitializing, interstitialLoading, showingAd, gamesInitialized, servicesStarted, disposed;
    private long bannerRetryAt;
    private long loadedAt;
    private volatile int adRequest;
    private int cloudRequest, conflictRetries, gamesRequest;
    private boolean gamesConnecting;
    private volatile String cloudDiagnostic = "";
    private Snapshot openSnapshot, conflictingSnapshot;
    private String conflictId;
    private int bottomInset;
    private final Handler handler = new Handler(Looper.getMainLooper());
    private static final String SAVE_NAME = "arenis_journey_v1";
    private static final int MAX_BYTES = 1048576;

    public ArenisAndroid(Godot godot) { super(godot); }
    @Override public String getPluginName() { return "ArenisAndroid"; }
    @Override public Set<SignalInfo> getPluginSignals() {
        Set<SignalInfo> signals = new HashSet<>();
        signals.add(new SignalInfo("banner_size", Integer.class, Integer.class));
        signals.add(new SignalInfo("safe_area", Integer.class, Integer.class));
        signals.add(new SignalInfo("privacy_state", Boolean.class));
        signals.add(new SignalInfo("interstitial_state", String.class));
        signals.add(new SignalInfo("cloud_snapshot", String.class, String.class));
        signals.add(new SignalInfo("cloud_state", String.class));
        return signals;
    }
    @Override public View onMainCreate(Activity activity) {
        overlay = new FrameLayout(activity);
        overlay.setClickable(false);
        overlay.addOnLayoutChangeListener((v,l,t,r,b,ol,ot,or,ob) -> measure());
        overlay.setOnApplyWindowInsetsListener((v, insets) -> { overlay.post(this::measure); return insets; });
        return overlay;
    }
    @Override public boolean shouldBeOnTop() { return true; }

    @UsedByGodot public boolean is_cloud_configured() { return BuildConfig.GAMES_CONFIGURED; }
    @UsedByGodot public void initialize_services() {
        runOnUiThread(() -> {
            servicesStarted = true;
            Activity activity = getActivity();
            if (activity == null) return;
            consent = UserMessagingPlatform.getConsentInformation(activity);
            consent.requestConsentInfoUpdate(activity, new ConsentRequestParameters.Builder().build(), () -> {
                UserMessagingPlatform.loadAndShowConsentFormIfRequired(activity, error -> {
                    publishPrivacy();
                    beginAds();
                });
                publishPrivacy();
            }, error -> { publishPrivacy(); beginAds(); });
            // A valid previous consent decision can allow requests while update runs.
            beginAds();
            overlay.post(this::measure);
        });
    }
    private void publishPrivacy() {
        emitSignal("privacy_state", consent != null && consent.getPrivacyOptionsRequirementStatus() == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED);
    }
    private void beginAds() {
        if (disposed || consent == null || !consent.canRequestAds() || adsInitializing) return;
        if (!adsInitialized) {
            adsInitializing = true;
            MobileAds.setRequestConfiguration(new RequestConfiguration.Builder().setMaxAdContentRating(RequestConfiguration.MAX_AD_CONTENT_RATING_G).build());
            MobileAds.initialize(getActivity(), status -> runOnUiThread(() -> {
                adsInitializing = false;
                adsInitialized = true;
                if (!disposed && consent.canRequestAds()) { loadBanner(); preloadInterstitial(); }
            }));
        } else { loadBanner(); preloadInterstitial(); }
    }
    private void loadBanner() {
        if (disposed || banner != null || overlay == null || overlay.getWidth() <= 0 || !consent.canRequestAds() || System.currentTimeMillis() < bannerRetryAt) return;
        Activity activity = getActivity();
        int widthDp = Math.max(1, (int)(overlay.getWidth() / activity.getResources().getDisplayMetrics().density));
        banner = new AdView(activity);
        banner.setAdUnitId(BuildConfig.BANNER_ID);
        banner.setAdSize(AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(activity, widthDp));
        banner.setVisibility(View.INVISIBLE);
        banner.addOnLayoutChangeListener((v,l,t,r,b,ol,ot,or,ob) -> measure());
        FrameLayout.LayoutParams layout = new FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.WRAP_CONTENT, Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL);
        layout.bottomMargin = bottomInset;
        overlay.addView(banner, layout);
        banner.setAdListener(new AdListener() {
            @Override public void onAdLoaded() { if (banner != null) { banner.setVisibility(View.VISIBLE); measure(); } }
            @Override public void onAdFailedToLoad(@NonNull LoadAdError error) {
                bannerRetryAt = System.currentTimeMillis() + 60000;
                if (banner != null) { overlay.removeView(banner); banner.destroy(); banner = null; }
                measure();
                handler.postDelayed(() -> { if (getActivity() != null && consent.canRequestAds()) loadBanner(); }, 60000);
            }
        });
        banner.loadAd(new AdRequest.Builder().build());
    }
    private void measure() {
        if (disposed || !servicesStarted || overlay == null || overlay.getWidth() <= 0) return;
        int top = 0;
        WindowInsets insets = overlay.getRootWindowInsets();
        if (insets != null) {
            int systemTop, systemBottom;
            if (Build.VERSION.SDK_INT >= 30) {
                android.graphics.Insets safe = insets.getInsets(WindowInsets.Type.systemBars() | WindowInsets.Type.displayCutout());
                systemTop = safe.top; systemBottom = safe.bottom;
            } else { systemTop = insets.getSystemWindowInsetTop(); systemBottom = insets.getSystemWindowInsetBottom(); }
            int[] location = new int[2];
            overlay.getLocationInWindow(location);
            View decor = getActivity().getWindow().getDecorView();
            top = Math.max(0, systemTop - location[1]);
            bottomInset = Math.max(0, location[1] + overlay.getHeight() - (decor.getHeight() - systemBottom));
        }
        int adHeight = 0;
        if (banner != null) {
            FrameLayout.LayoutParams layout = (FrameLayout.LayoutParams)banner.getLayoutParams();
            if (layout.bottomMargin != bottomInset) { layout.bottomMargin = bottomInset; banner.setLayoutParams(layout); }
            if (banner.getVisibility() == View.VISIBLE) adHeight = Math.max(banner.getHeight(), banner.getAdSize().getHeightInPixels(getActivity()));
        }
        emitSignal("safe_area", overlay.getWidth(), top);
        emitSignal("banner_size", overlay.getWidth(), adHeight + bottomInset);
        if (adsInitialized && banner == null && consent.canRequestAds() && System.currentTimeMillis() >= bannerRetryAt) {
            // Creation is posted to avoid mutating the view tree during layout.
            overlay.post(this::loadBanner);
        }
    }
    private void preloadInterstitial() {
        if (disposed || !adsInitialized || !consent.canRequestAds() || interstitialLoading || interstitial != null) return;
        interstitialLoading = true;
        InterstitialAd.load(getActivity(), BuildConfig.INTERSTITIAL_ID, new AdRequest.Builder().build(), new InterstitialAdLoadCallback() {
            @Override public void onAdLoaded(@NonNull InterstitialAd ad) {
                interstitialLoading = false;
                if (!disposed && consent.canRequestAds()) { interstitial = ad; loadedAt = System.currentTimeMillis(); }
            }
            @Override public void onAdFailedToLoad(@NonNull LoadAdError error) { interstitialLoading = false; interstitial = null; }
        });
    }
    @UsedByGodot public void show_interstitial() {
        final int request = ++adRequest;
        runOnUiThread(() -> {
            if (disposed || request != adRequest || showingAd) return;
            if (interstitial == null || consent == null || !consent.canRequestAds() || System.currentTimeMillis() - loadedAt >= 3500000) {
                interstitial = null;
                emitSignal("interstitial_state", "unavailable");
                preloadInterstitial();
                return;
            }
            InterstitialAd ad = interstitial;
            interstitial = null;
            ad.setFullScreenContentCallback(new FullScreenContentCallback() {
                @Override public void onAdShowedFullScreenContent() { showingAd = true; emitSignal("interstitial_state", "shown"); }
                @Override public void onAdDismissedFullScreenContent() { showingAd = false; emitSignal("interstitial_state", "closed"); preloadInterstitial(); }
                @Override public void onAdFailedToShowFullScreenContent(@NonNull AdError error) { showingAd = false; emitSignal("interstitial_state", "failed"); preloadInterstitial(); }
            });
            if (request == adRequest) ad.show(getActivity());
        });
    }
    @UsedByGodot public void cancel_interstitial() { if (!showingAd) ++adRequest; }
    @UsedByGodot public void show_privacy_options() {
        runOnUiThread(() -> UserMessagingPlatform.showPrivacyOptionsForm(getActivity(), error -> {
            publishPrivacy();
            bannerRetryAt = 0;
            interstitial = null;
            if (banner != null) { overlay.removeView(banner); banner.destroy(); banner = null; }
            measure();
            beginAds();
        }));
    }

    @UsedByGodot public boolean is_debug_build() { return (getActivity().getApplicationInfo().flags & ApplicationInfo.FLAG_DEBUGGABLE) != 0; }
    @UsedByGodot public String get_cloud_diagnostic() { return cloudDiagnostic; }
    private void cloudFailure(String stage, Exception error) {
        String detail = error instanceof ApiException ? "status=" + ((ApiException) error).getStatusCode()
            : error == null ? "not_authenticated" : error.getClass().getSimpleName();
        cloudDiagnostic = stage + " / " + detail;
        // No account identifiers, payloads, tokens or exception messages in diagnostics.
        Log.w("ArenisCloud", cloudDiagnostic);
        emitSignal("cloud_state", "failed");
    }
    @UsedByGodot public void connect_games() {
        runOnUiThread(() -> {
            if (disposed || gamesConnecting) return;
            if (!BuildConfig.GAMES_CONFIGURED) { emitSignal("cloud_state", "unavailable"); return; }
            int request = ++gamesRequest;
            gamesConnecting = true;
            cloudDiagnostic = "";
            try {
                if (!gamesInitialized) { PlayGamesSdk.initialize(getActivity().getApplication()); gamesInitialized = true; }
                PlayGames.getGamesSignInClient(getActivity()).isAuthenticated().addOnCompleteListener(task -> {
                    if (disposed || request != gamesRequest) return;
                    if (task.isSuccessful() && task.getResult().isAuthenticated()) {
                        gamesConnecting = false;
                        emitSignal("cloud_state", "connected");
                    } else {
                        PlayGames.getGamesSignInClient(getActivity()).signIn().addOnCompleteListener(login -> {
                            if (disposed || request != gamesRequest) return;
                            gamesConnecting = false;
                            if (login.isSuccessful() && login.getResult().isAuthenticated()) emitSignal("cloud_state", "connected");
                            else cloudFailure("sign_in", login.getException());
                        });
                    }
                });
            } catch (Exception error) { gamesConnecting = false; cloudFailure("initialize", error); }
        });
    }
    @UsedByGodot public void read_cloud() {
        runOnUiThread(() -> {
            if (!BuildConfig.GAMES_CONFIGURED || !gamesInitialized) { cloudFailure("snapshot_not_connected", null); return; }
            cloudDiagnostic = "";
            closeSnapshots();
            int request = ++cloudRequest;
            conflictRetries = 0;
            PlayGames.getSnapshotsClient(getActivity()).open(SAVE_NAME, true, SnapshotsClient.RESOLUTION_POLICY_MANUAL).addOnCompleteListener(task -> {
                if (!task.isSuccessful()) { if (request == cloudRequest) cloudFailure("snapshot_open", task.getException()); return; }
                processSnapshot(task.getResult(), request);
            });
        });
    }
    private String read(Snapshot snapshot) throws Exception {
        byte[] bytes = snapshot.getSnapshotContents().readFully();
        if (bytes.length > MAX_BYTES) throw new IllegalArgumentException("Snapshot exceeds limit");
        return new String(bytes, StandardCharsets.UTF_8);
    }
    private void processSnapshot(SnapshotsClient.DataOrConflict<Snapshot> result, int request) {
        if (request != cloudRequest) {
            if (result.isConflict()) { discard(result.getConflict().getSnapshot()); discard(result.getConflict().getConflictingSnapshot()); }
            else discard(result.getData());
            return;
        }
        try {
            if (result.isConflict()) {
                if (++conflictRetries > 5) throw new IllegalStateException("Too many conflicts");
                SnapshotsClient.SnapshotConflict conflict = result.getConflict();
                openSnapshot = conflict.getSnapshot();
                conflictingSnapshot = conflict.getConflictingSnapshot();
                conflictId = conflict.getConflictId();
                emitSignal("cloud_snapshot", read(openSnapshot), read(conflictingSnapshot));
            } else {
                openSnapshot = result.getData(); conflictingSnapshot = null; conflictId = null;
                emitSignal("cloud_snapshot", read(openSnapshot), "");
            }
        } catch (Exception error) { closeSnapshots(); cloudFailure("snapshot_read", error); }
    }
    @UsedByGodot public void write_cloud(String payload) {
        runOnUiThread(() -> {
            try {
                byte[] bytes = payload.getBytes(StandardCharsets.UTF_8);
                if (openSnapshot == null || bytes.length > MAX_BYTES) throw new IllegalStateException("Invalid snapshot write");
                int request = cloudRequest;
                openSnapshot.getSnapshotContents().writeBytes(bytes);
                SnapshotsClient client = PlayGames.getSnapshotsClient(getActivity());
                SnapshotMetadataChange change = new SnapshotMetadataChange.Builder().setDescription("Arenis completed levels and best scores").build();
                if (conflictId != null) {
                    Snapshot resolution = openSnapshot;
                    openSnapshot = null; conflictingSnapshot = null;
                    String id = conflictId; conflictId = null;
                    client.resolveConflict(id, resolution).addOnCompleteListener(task -> {
                        if (task.isSuccessful()) processSnapshot(task.getResult(), request);
                        else if (request == cloudRequest) { closeSnapshots(); cloudFailure("snapshot_conflict", task.getException()); }
                    });
                } else {
                    Snapshot snapshot = openSnapshot; openSnapshot = null;
                    client.commitAndClose(snapshot, change).addOnCompleteListener(task -> {
                        if (request == cloudRequest) {
                            if (task.isSuccessful()) { cloudDiagnostic = ""; emitSignal("cloud_state", "saved"); }
                            else cloudFailure("snapshot_commit", task.getException());
                        }
                    });
                }
            } catch (Exception error) { closeSnapshots(); cloudFailure("snapshot_write", error); }
        });
    }
    @UsedByGodot public void cancel_cloud() { runOnUiThread(() -> { ++cloudRequest; ++gamesRequest; gamesConnecting = false; closeSnapshots(); }); }
    private void discard(Snapshot snapshot) {
        if (snapshot != null && getActivity() != null) PlayGames.getSnapshotsClient(getActivity()).discardAndClose(snapshot);
    }
    private void closeSnapshots() {
        discard(openSnapshot); discard(conflictingSnapshot);
        openSnapshot = null; conflictingSnapshot = null; conflictId = null;
    }
    @Override public void onMainPause() { if (banner != null) banner.pause(); }
    @Override public void onMainResume() { if (banner != null) banner.resume(); if (overlay != null) overlay.post(this::measure); }
    @Override public void onMainDestroy() {
        disposed = true;
        ++adRequest; ++cloudRequest; ++gamesRequest; handler.removeCallbacksAndMessages(null); closeSnapshots();
        if (banner != null) { banner.destroy(); banner = null; }
        interstitial = null;
    }
}
