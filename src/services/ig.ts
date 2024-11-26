import axios, { AxiosInstance } from "axios";

export interface IIgAccount {
  user_id: string;
  username: string;
  followers_count: number;
  follows_count: number;
  media_count: number;
  profile_picture_url: string;
  biography: string;
  id: string;
}
export class IGService {
  private static axiosInstance: AxiosInstance;
  private static ACCESS_TOKENS: string[] = [];
  public static initialized = true;
  public static IgAccounts: IIgAccount[] = [];

  public static init = async (access_tokens: string[]) => {
    this.ACCESS_TOKENS = access_tokens;
    this.axiosInstance = axios.create({
      baseURL: "https://graph.instagram.com",
    });
    const localAccounts: [] = JSON.parse(
      localStorage.getItem("IgAccounts") || "[]",
    );
    if (!!localAccounts && localAccounts.length > 0) {
      this.IgAccounts = localAccounts;
      return this.IgAccounts;
    }
    const r = this.ACCESS_TOKENS.map(async (e) => {
      try {
        const page_id = await this.getUserId(e);
        const userInfo = await this.getUserInfo(page_id, e);
        return userInfo;
      } catch (error) {
        throw error;
      }
    });
    this.IgAccounts = await Promise.all(r);
    localStorage.setItem("IgAccounts", JSON.stringify(this.IgAccounts));
    return this.IgAccounts;
  };

  public static publishMedia = async (
    urls: string[],
    caption: string,
    account: IIgAccount,
    access_token: string,
  ) => {
    if (!this.initialized) {
      throw new Error("IgService has not been initialized");
    }
    try {
      const reqs = urls.map((e) => {
        return this.axiosInstance.post(`/${account.user_id}/media`, null, {
          params: {
            access_token,
            image_url: e,
            is_carousel_item: true,
          },
        });
      });
      const res = await Promise.all(reqs);
      const carouselContainerRes = await this.axiosInstance.post(
        `/${account.user_id}/media`,
        null,
        {
          params: {
            access_token,
            media_type: "CAROUSEL",
            children: res.map((e) => e.data.id).join(","),
            caption,
          },
        },
      );
      const carouselRes = await this.axiosInstance.post(
        `/${account.user_id}/media_publish`,
        null,
        {
          params: {
            access_token,
            creation_id: carouselContainerRes.data.id,
          },
        },
      );
      console.log(
        "✅✅✅✅✅✅✅✅✅✅✅✅✅✅\nSuccessfully created carousel\n✅✅✅✅✅✅✅✅✅✅✅✅✅✅",
      );
    } catch (error) {
      throw new Error("Error in publishing carousel ", error);
    }
  };

  public static getChannels = async () => {
    if (!this.initialized) {
      throw new Error("IgService has not been initialized");
    }
    return [];
  };

  private static getUserId = async (access_token: string): Promise<string> => {
    try {
      const res = await this.axiosInstance.get("/me?fields=user_id", {
        params: { access_token },
      });
      return res.data.user_id;
    } catch (error) {
      throw new Error("Cannot get user_id", error);
    }
  };
  private static getUserInfo = async (
    page_id: string,
    access_token: string,
  ): Promise<IIgAccount> => {
    try {
      const res = await this.axiosInstance.get(
        `/${page_id}?fields=user_id,name,username,followers_count,follows_count,media_count,profile_picture_url,biography`,
        { params: { access_token } },
      );
      return res.data;
    } catch (error) {
      throw new Error("Cannot get user info", error);
    }
  };
}
