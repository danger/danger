RSpec.describe Danger::Helpers::ArraySubclass do
  class List; include Danger::Helpers::ArraySubclass; end
  class OtherList; include Danger::Helpers::ArraySubclass; end

  it "acts as array" do
    first_list = List.new([1, 2, 3])
    second_list = List.new([4, 5, 6])
    third_list = List.new([1, 2, 3])
    fourth_list = List.new([7, 7])

    mapped_list = first_list.map { |item| item + 1 }
    concated_list = first_list + second_list
    mapped_mutated_list = third_list.map! { |item| item + 10 }
    deleted_from_list = fourth_list.delete_at(0)
    reduced_list = first_list.each_with_object({}) do |el, accum|
      accum.store(el, el)
    end

    expect(first_list.length).to eq(3)
    expect(mapped_list).to eq(List.new([2, 3, 4]))
    expect(concated_list).to eq(List.new([1, 2, 3, 4, 5, 6]))
    expect(third_list).to eq(List.new([11, 12, 13]))
    expect(mapped_mutated_list).to eq(List.new([11, 12, 13]))
    expect(deleted_from_list).to eq(7)
    expect(fourth_list).to eq(List.new([7]))
    expect(reduced_list).to eq({ 1 => 1, 2 => 2, 3 => 3 })
  end

  describe "equality" do
    it "equals with same class same size and same values" do
      first_list = List.new([1, 2, 3])
      second_list = List.new([1, 2, 3])
      third_list = List.new([4, 5, 6])

      expect(first_list).to eq(second_list)
      expect(first_list).not_to eq(third_list)
    end

    it "not equals with other classes" do
      first_list = List.new([1, 2, 3])
      second_list = OtherList.new([1, 2, 3])
      third_list = [4, 5, 6]

      expect(first_list).not_to eq(second_list)
      expect(first_list).not_to eq(third_list)
    end
  end
end
