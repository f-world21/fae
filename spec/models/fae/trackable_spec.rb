require 'rails_helper'

describe Fae::Trackable do

  describe 'after_create' do
    it 'should create a change item related to the model' do
      wine = FactoryGirl.create(:wine)

      change = Fae::Change.last
      expect(change.changeable_id).to eq(wine.id)
      expect(change.changeable_type).to eq('Wine')
      expect(change.change_type).to eq('created')
    end

    context 'when fae_tracker_blacklist == all' do
      it 'should not create change item' do
        aroma = FactoryGirl.create(:aroma)
        expect(aroma.tracked_changes).to eq([])
      end
    end
  end

  describe 'before_update' do
    it 'should create a change item related to the model' do
      wine = FactoryGirl.create(:wine)
      wine.update({name_en: 'new name', description_en: 'new desc', food_pairing_en: 'new pairing'})

      change = Fae::Change.last
      expect(change.changeable_id).to eq(wine.id)
      expect(change.changeable_type).to eq('Wine')
      expect(change.change_type).to eq('updated')
      expect(change.updated_attributes).to eq(['name_en', 'description_en', 'food_pairing_en'])
    end

    it 'should not create item if no changes were made' do
      wine = FactoryGirl.create(:wine, name_en: 'test')
      wine.update({name_en: 'test'})

      change = Fae::Change.last
      expect(change.changeable_id).to eq(wine.id)
      expect(change.changeable_type).to eq('Wine')
      expect(change.change_type).to eq('created')
    end

    context 'when fae_tracker_blacklist == all' do
      it 'should not create change item' do
        aroma = FactoryGirl.create(:aroma)
        aroma.update({name: 'something else'})
        expect(aroma.tracked_changes).to eq([])
      end
    end

    context 'when fae_tracker_blacklist contains attributes' do
      it 'should not create a change item if only blacklisted attribues change' do
        release = FactoryGirl.create(:release)
        release.update({position: 5})
        expect(release.tracked_changes.length).to eq(1)
        expect(release.tracked_changes.first.change_type).to eq('created')
      end

      it 'should not include blacklisted attributes in updated_attributes' do
        release = FactoryGirl.create(:release)
        release.update({name: 'new name', slug: 'new_slug', price: 15})
        expect(release.tracked_changes.length).to eq(2)
        expect(release.tracked_changes.first.updated_attributes).to_not include('price')
      end
    end
  end

  describe 'before_destroy' do
    it 'should create a change item related to the model' do
      wine = FactoryGirl.create(:wine)
      wine.destroy

      change = Fae::Change.last
      expect(change.changeable_id).to eq(wine.id)
      expect(change.changeable_type).to eq('Wine')
      expect(change.change_type).to eq('deleted')
    end

    context 'when fae_tracker_blacklist == all' do
      it 'should not create change item' do
        aroma = FactoryGirl.create(:aroma)
        aroma.destroy
        expect(Fae::Change.where(changeable_type: 'Aroma')).to eq([])
      end
    end
  end

  describe 'tracked_changes' do
    it 'should assign association to parent object' do
      wine = FactoryGirl.create(:wine)
      wine.update({name_en: 'testttt'})
      expect(wine.tracked_changes.length).to eq(2)
    end

    it 'should assign no more than Fae.tracker_history_length changes' do
      wine = FactoryGirl.create(:wine, name_en: 'change 1')
      wine.update({name_en: 'change 2'})
      wine.update({name_en: 'change 3'})
      wine.update({name_en: 'change 4'})
      wine.update({name_en: 'change 5'})
      wine.update({name_en: 'change 6'})
      wine.update({name_en: 'change 7'})
      wine.update({name_en: 'change 8'})
      wine.update({name_en: 'change 9'})
      wine.update({name_en: 'change 10'})
      wine.update({name_en: 'change 11'})
      wine.update({name_en: 'change 12'})
      wine.update({name_en: 'change 13'})
      wine.update({name_en: 'change 14'})
      wine.update({name_en: 'change 15'})
      wine.update({name_en: 'change 16'})
      wine.update({description_en: 'change 17'})

      expect(wine.tracked_changes.length).to eq(Fae.tracker_history_length)
      expect(wine.tracked_changes.first.updated_attributes).to eq(['description_en'])
    end
  end

end