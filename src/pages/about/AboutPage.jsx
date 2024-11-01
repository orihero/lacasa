import React from "react";
import "./about.scss";

const AboutPage = () => {
  return (
    <div className="about">
      <div className="about-item">
        <div className="about-title">
          <h1>Saytimizning Maqsadi</h1>
        </div>
        <div className="about-content">
          <div className="item-text">
            <p>
              Bizning platformamizning asosiy maqsadi – uy sotish va sotib olish
              jarayonlarini soddalashtirish, har bir foydalanuvchi uchun tez va
              qulay interfeys yaratishdir. Uyni qidirish – bu faqatgina jismoniy
              makon emas, balki orzular, umidlar va kelajak rejalari uchun yangi
              boshlanishdir. Platformamiz yordamida xaridorlar o‘z ehtiyojlariga
              va byudjetlariga mos keladigan uylarni tanlashda keng
              imkoniyatlarga ega. Saytimizda uylarning joylashuvi, kvadrat
              metraj, narx va boshqa muhim ma'lumotlar aniq va tushunarli tarzda
              ko‘rsatilgan. Qulay qidiruv filtrlari orqali siz bir necha
              daqiqalar ichida o‘zingiz uchun eng mos uyni topishingiz mumkin.
              Bizning vazifamiz – sizga ishonchli, shaffof va qulay platformani
              taqdim etishdir, shunda siz uyingizni topishda o‘zingizni to‘liq
              ishonch bilan his qilishingiz mumkin.
            </p>
          </div>
          <div className="item-photo">
            <img src="/about2.webp" alt="" />
          </div>
        </div>
      </div>
      <div className="about-item reverse">
        <div className="about-title">
          <h1>Xaridorlar uchun Imkoniyatlar</h1>
        </div>
        <div className="about-content">
          <div className="item-text">
            <p>
              Xaridor sifatida ro‘yxatdan o‘tgan foydalanuvchilar platformamiz
              orqali keng ko‘lamdagi uy e'lonlarini ko‘rib chiqishlari mumkin.
              Siz o‘z talablarga mos uyni topish uchun joylashuv, narx
              diapazoni, kvadrat metraj va boshqa filtrlarni qo‘llashingiz
              mumkin. Har bir e'lon uy haqida batafsil ma'lumot, sifatli
              suratlar va uyning xonadon rejalari bilan to‘ldirilgan.
              Shuningdek, joylashuv xaritasi va atrofidagi infratuzilma haqida
              ham ma'lumot beriladi. Biz sizga qulay va aniq qidiruv
              imkoniyatlari yaratib, kerakli uyni qidirish jarayonini
              osonlashtiramiz. Siz faqatgina saytimiz orqali o‘zingizga yoqqan
              uylarni tanlab, keyingi bosqichda arzonroq narxga kelishish yoki
              qo‘shimcha ma'lumot olish uchun to‘g‘ridan-to‘g‘ri realtorlar
              bilan bog‘lanishingiz mumkin.
            </p>
          </div>
          <div className="item-photo">
            <img src="/about3.webp" alt="" />
          </div>
        </div>
      </div>
      <div className="about-item">
        <div className="about-title">
          <h1>Realtorlar uchun Samaradorlik</h1>
        </div>
        <div className="about-content">
          <div className="item-text">
            <p>
              Realtorlar uchun bizning platformamiz – mijozlarga tez va samarali
              xizmat ko‘rsatish uchun eng yaxshi vosita. Realtor sifatida
              ro‘yxatdan o‘tganingizdan so‘ng, yangi uy e'lonlarini tez va oson
              joylashtirishingiz mumkin. Har bir e'lonni yaratish jarayoni
              intuitiv va sodda qilib tuzilgan, shunda siz har bir mijoz uchun
              sifatli va dolzarb e'lonlarni tezda tayyorlab, joylashtira olasiz.
              Bundan tashqari, e'lonlaringiz avtomatik ravishda platformamiz
              bilan bog‘langan Telegram kanali va Instagram sahifasiga chiqadi,
              bu esa sizning e'lonlaringizni keng auditoriyaga yetkazadi.
              Ko‘proq mijoz jalb qilish va tezroq savdolar amalga oshirish uchun
              saytimizdagi imkoniyatlardan to‘liq foydalaning. Sizning har bir
              e'loningizni ko‘proq mijozlar ko‘radi va qiziqish bildiradi.
            </p>
          </div>
          <div className="item-photo">
            <img src="/about1.webp" alt="" />
          </div>
        </div>
      </div>
    </div>
  );
};

export default AboutPage;
