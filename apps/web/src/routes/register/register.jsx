import { Link, useNavigate } from "react-router-dom";
import { toast } from "react-toastify";
import { api, setAuthToken } from "../../lib/api";
import "./register.scss";
import { useState } from "react";
import { Triangle } from "react-loader-spinner";
import { TEAM_SIZE, registerSchema } from "@lacasa/domain";
import { useUserStore } from "../../lib/userStore";
import { useListStore } from "../../lib/adsListStore";

// Labels for @lacasa/domain's TEAM_SIZE keys — the package owns the
// vocabulary, this file owns how it reads (see mockups/SCREENS.md §13).
const TEAM_SIZE_LABELS = {
  just_me: "Just me for now",
  two_to_five: "2–5",
  six_to_fifteen: "6–15",
  sixteen_plus: "16+",
};

const TEAM_SIZE_KEYS = Object.keys(TEAM_SIZE);

function Register() {
  const navigate = useNavigate();
  const [isLoading, setIsLoading] = useState(false);
  // The two toggles from SCREENS.md §13. Everything else on this form is
  // still uncontrolled and read out of FormData on submit.
  const [accountType, setAccountType] = useState("buyer");
  const [realtorKind, setRealtorKind] = useState("solo");
  const [teamSize, setTeamSize] = useState(TEAM_SIZE_KEYS[0]);
  const { fetchUserInfo } = useUserStore();
  const { fetchAdsList } = useListStore();

  const isRealtor = accountType === "realtor";
  const isAgency = isRealtor && realtorKind === "agency";

  // The `realtor` half of the payload, shaped for @lacasa/domain's
  // realtorApplicationSchema — omitted entirely for a buyer.
  const buildRealtor = (form) => {
    if (!isRealtor) return undefined;
    if (realtorKind === "solo") return { kind: "solo" };
    return {
      kind: "agency",
      agencyName: form.agencyName?.trim(),
      // Optional field: send it only when filled, or the +998 rule rejects "".
      ...(form.officePhone?.trim() ? { officePhone: form.officePhone.trim() } : {}),
      teamSize,
    };
  };

  const handleRegister = async (e) => {
    e.preventDefault();

    const form = Object.fromEntries(new FormData(e.target));
    const { fullName, email, password, phoneNumber } = form;
    const payload = { fullName, email, password, phoneNumber, realtor: buildRealtor(form) };

    // Same schema the API validates against, so a bad agency name or office
    // phone is caught here instead of coming back as a 400.
    const parsed = registerSchema.safeParse(payload);
    if (!parsed.success) {
      toast.error(parsed.error.issues[0].message);
      return;
    }

    setIsLoading(true);
    try {
      const { data } = await api.post("/auth/register", parsed.data);
      setAuthToken(data.token);
      await fetchUserInfo();
      fetchAdsList();

      toast.success(
        isRealtor
          ? "Account created. We'll verify your realtor profile shortly."
          : "User successfully created",
      );
      navigate("/");
    } catch (error) {
      console.error(error);
      toast.error(
        `Error
        ${error?.response?.data?.error?.message ?? error.message}`,
      );
    }

    setIsLoading(false);
  };

  if (isLoading) {
    return (
      <div className="loading">
        <Triangle
          visible={true}
          height="80"
          width="80"
          color="#4fa94d"
          ariaLabel="triangle-loading"
          wrapperStyle={{}}
          wrapperClass=""
        />
      </div>
    );
  }

  return (
    <div className="register">
      <div className="formContainer">
        <form onSubmit={handleRegister}>
          <h1>Create an Account</h1>
          <p className="lead">
            Browsing and saving work on any account. A realtor account adds the workspace —
            listings, leads and publishing.
          </p>

          <fieldset className="picks">
            <legend>I&rsquo;m signing up as</legend>
            <div className="opts">
              <button
                type="button"
                className={accountType === "buyer" ? "pick on" : "pick"}
                aria-pressed={accountType === "buyer"}
                onClick={() => setAccountType("buyer")}
              >
                <span className="pick__t">Buyer</span>
                <span className="pick__s">Browse and save homes</span>
              </button>
              <button
                type="button"
                className={isRealtor ? "pick on" : "pick"}
                aria-pressed={isRealtor}
                onClick={() => setAccountType("realtor")}
              >
                <span className="pick__t">Realtor</span>
                <span className="pick__s">Post listings, work leads</span>
              </button>
            </div>
          </fieldset>

          <input required name="fullName" type="text" placeholder="Full name" />
          <input
            required
            name="phoneNumber"
            type="tel"
            placeholder="Phone number"
          />
          <input required name="email" type="text" placeholder="Email" />
          <input
            required
            name="password"
            type="password"
            placeholder="Password"
          />

          {isRealtor && (
            <>
              <fieldset className="segs">
                <legend>Realtor type</legend>
                <div className="opts">
                  <button
                    type="button"
                    className={realtorKind === "solo" ? "seg on" : "seg"}
                    aria-pressed={realtorKind === "solo"}
                    onClick={() => setRealtorKind("solo")}
                  >
                    Solo agent
                  </button>
                  <button
                    type="button"
                    className={isAgency ? "seg on" : "seg"}
                    aria-pressed={isAgency}
                    onClick={() => setRealtorKind("agency")}
                  >
                    Agency
                  </button>
                </div>
              </fieldset>

              {isAgency ? (
                <>
                  <input
                    required
                    name="agencyName"
                    type="text"
                    placeholder="Agency name"
                  />
                  <p className="hint">
                    Shown on every listing your team publishes, in place of the agent&rsquo;s own
                    name.
                  </p>
                  <input
                    name="officePhone"
                    type="tel"
                    placeholder="Office phone (optional)"
                  />
                  <fieldset className="segs">
                    <legend>Team size</legend>
                    <div className="opts">
                      {TEAM_SIZE_KEYS.map((key) => (
                        <button
                          key={key}
                          type="button"
                          className={teamSize === key ? "seg on" : "seg"}
                          aria-pressed={teamSize === key}
                          onClick={() => setTeamSize(key)}
                        >
                          {TEAM_SIZE_LABELS[key]}
                        </button>
                      ))}
                    </div>
                  </fieldset>
                  <p className="hint">
                    You sign up as the agency owner: invite coworkers, assign leads to them, and
                    see the whole team&rsquo;s statistics.
                  </p>
                </>
              ) : (
                <p className="hint">
                  You work under your own name. Coworkers stay hidden until you switch to an agency
                  account.
                </p>
              )}

              <p className="callout">
                Realtor accounts are verified before the workspace unlocks. We&rsquo;ll call the
                number above — usually within one business day.
              </p>
            </>
          )}

          <button>{isRealtor ? "Create realtor account" : "Register"}</button>
          <Link to="/login">Do you have an account?</Link>
        </form>
      </div>
      <div className="imgContainer">
        <img src="/bg.png" alt="" />
      </div>
    </div>
  );
}

export default Register;
