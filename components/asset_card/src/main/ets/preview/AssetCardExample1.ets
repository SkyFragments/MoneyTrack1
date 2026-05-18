import { AssetCard } from '../components/AssetCard';

@Entry
@ComponentV2
struct AssetCardExample1 {
  build() {
    Column() {
      AssetCard();
    }
    .padding(16)
    .backgroundColor('#eee');
  }
}