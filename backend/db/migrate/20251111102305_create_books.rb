class CreateBooks < ActiveRecord::Migration[7.1]
  def change
    create_table :books do |t|
      t.string :title, null: false
      t.string :author, null: false
      t.string :genre, null: false
      t.string :isbn, null: false
      t.integer :total_copies, null: false, default: 1
      t.text :description

      t.timestamps
    end

    add_index :books, :isbn, unique: true
    add_index :books, :title
    add_index :books, :author
    add_index :books, :genre
    add_check_constraint :books, "total_copies >= 0", name: "books_total_copies_positive"
  end
end
