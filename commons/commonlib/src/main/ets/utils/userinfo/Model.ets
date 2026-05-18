import { GenderType } from 'collect_personal_info';

@ObservedV2
export class UserInfoModel {
  @Trace
  public nickname: string = '';
  @Trace
  public phone: string = '';
  @Trace
  public avatar: ResourceStr = '';
  @Trace
  public name: string = '';
  @Trace
  public birth: Date = new Date();
  @Trace
  public gender: GenderType = GenderType.CONFIDENTIALITY;
  @Trace
  public anonymousPhone: string = ''
  @Trace
  public isMember: boolean = false

  public reset(): void {
    this.nickname = '';
    this.phone = '';
    this.avatar = '';
    this.name = '';
    this.birth = new Date();
    this.gender = GenderType.CONFIDENTIALITY;
    this.anonymousPhone = '';
  }
}