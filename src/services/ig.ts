import axios, { AxiosInstance } from "axios";

export interface IIgAccount {
  id: string;
  username: string;
  followers_count: number;
  follows_count: number;
  media_count: number;
  profile_picture_url: string;
  biography: string;
}

export class IGService {
  private static axiosInstance: AxiosInstance;
  private static ACCESS_TOKENS: string[] = [];
  public static initialized = false;
  public static IgAccounts: IIgAccount[] = [];

  // Initialize the Instagram service
  public static init = async (
    access_tokens: string[],
  ): Promise<IIgAccount[]> => {
    try {
      this.ACCESS_TOKENS = access_tokens;
      this.axiosInstance = axios.create({
        baseURL: "https://graph.instagram.com",
      });
      this.initialized = true;

      const localAccounts: IIgAccount[] = JSON.parse(
        localStorage.getItem("IgAccounts") || "[]",
      );

      if (localAccounts && localAccounts.length > 0) {
        this.IgAccounts = localAccounts;
        return this.IgAccounts;
      }

      const fetchAccounts = this.ACCESS_TOKENS.map(async (token) => {
        try {
          const page_id = await this.getUserId(token);
          return await this.getUserInfo(page_id, token);
        } catch (error) {
          console.error("Failed to fetch account details:", error);
          return null; // Skip this account if there is an error
        }
      });

      // Resolve all valid accounts
      const resolvedAccounts = await Promise.all(fetchAccounts);
      this.IgAccounts = resolvedAccounts.filter(
        (account): account is IIgAccount => account !== null,
      );

      localStorage.setItem("IgAccounts", JSON.stringify(this.IgAccounts));
      return this.IgAccounts;
    } catch (error) {
      console.error("Error initializing IGService:", error);
      return [];
    }
  };

  // Publish media as a carousel
  public static publishMedia = async (
    urls: string[],
    caption: string,
    account: IIgAccount,
    access_token: string,
  ): Promise<void> => {
    if (!this.initialized) {
      throw new Error("IGService has not been initialized");
    }

    try {
      const mediaIds = await Promise.all(
        urls.map(async (url) => {
          try {
            const res = await this.axiosInstance.post(
              `/${account.id}/media`,
              null,
              {
                params: {
                  access_token,
                  image_url: url,
                  is_carousel_item: true,
                },
              },
            );
            return res.data.id;
          } catch (error) {
            console.error("Failed to upload media:", error);
            return null;
          }
        }),
      );

      const validMediaIds = mediaIds.filter((id): id is string => id !== null);

      if (validMediaIds.length === 0) {
        throw new Error("No valid media items were uploaded");
      }

      // Create the carousel container
      const carouselContainerRes = await this.axiosInstance.post(
        `/${account.id}/media`,
        null,
        {
          params: {
            access_token,
            media_type: "CAROUSEL",
            children: validMediaIds,
            caption,
          },
        },
      );

      // Publish the carousel
      await this.axiosInstance.post(`/${account.id}/media_publish`, null, {
        params: {
          access_token,
          creation_id: carouselContainerRes.data.id,
        },
      });

      console.log("✅ Successfully created and published carousel!");
    } catch (error) {
      console.error("Error in publishing carousel:", error);
    }
  };

  // Fetch connected channels (placeholder for now)
  public static getChannels = async (): Promise<IIgAccount[]> => {
    if (!this.initialized) {
      throw new Error("IGService has not been initialized");
    }
    return this.IgAccounts;
  };

  // Get the user ID from the access token
  private static getUserId = async (access_token: string): Promise<string> => {
    try {
      const res = await this.axiosInstance.get("/me?fields=id", {
        params: { access_token },
      });
      return res.data.id;
    } catch (error) {
      console.error("Failed to fetch user ID:", error);
      throw new Error("Cannot get user_id");
    }
  };

  // Get detailed user information
  private static getUserInfo = async (
    page_id: string,
    access_token: string,
  ): Promise<IIgAccount> => {
    try {
      const res = await this.axiosInstance.get(
        `/${page_id}?fields=id,username,followers_count,follows_count,media_count,profile_picture_url,biography`,
        { params: { access_token } },
      );
      return res.data;
    } catch (error) {
      console.error("Failed to fetch user info:", error);
      throw new Error("Cannot get user info");
    }
  };
}
