import { PersonalInfoView } from 'collect_personal_info';
import { EditProfileVM } from '../viewmodels/EditProfileVM';

@Builder
export function buildEditProfilePage() {
  EditProfilePage();
}

@ComponentV2
export struct EditProfilePage{
  vm: EditProfileVM = new EditProfileVM();

  build() {
    NavDestination() {
      Column() {
        PersonalInfoView({
          list: this.vm.list,
          themeColor: $r('app.color.system_theme_color'),
        })
      }
      .width('100%')
      .height('100%')
      .padding(16)
    }
    .title('个人信息')
    .backgroundColor($r('sys.color.background_secondary'))
  }
}