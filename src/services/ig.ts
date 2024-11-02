import axios from "axios";

export class IgService {
  //@ts-ignore
  public static ACCESS_TOKEN = import.meta.env.VITE_LECASA_IG_ACCESS_TOKEN;
  //@ts-ignore
  public static PAGE_ID = import.meta.env.VITE_LECASA_IG_PAGE_ID;

  public static customCreateCarousel = async (
    urls: string[],
    caption: string
  ) => {
    try {
      const reqs = urls.map((e) => {
        return axios.post(
          `https://graph.instagram.com/${IgService.PAGE_ID}/media`,
          null,
          {
            params: {
              access_token: IgService.ACCESS_TOKEN,
              image_url: e,
              is_carousel_item: true,
            },
          }
        );
      });
      const res = await Promise.all(reqs);
      const carouselContainerRes = await axios.post(
        `https://graph.instagram.com/${IgService.PAGE_ID}/media`,
        null,
        {
          params: {
            access_token: IgService.ACCESS_TOKEN,
            media_type: "CAROUSEL",
            children: res.map((e) => e.data.id).join(","),
            caption,
          },
        }
      );
      const carouselRes = await await axios.post(
        `https://graph.instagram.com/${IgService.PAGE_ID}/media_publish`,
        null,
        {
          params: {
            access_token: IgService.ACCESS_TOKEN,
            creation_id: carouselContainerRes.data.id,
          },
        }
      );
      console.log(
        "✅✅✅✅✅✅✅✅✅✅✅✅✅✅\nSuccessfully created carousel\n✅✅✅✅✅✅✅✅✅✅✅✅✅✅"
      );
    } catch (error) {
      throw new Error("Error in publishing carousel ", error);
    }
  };
}
