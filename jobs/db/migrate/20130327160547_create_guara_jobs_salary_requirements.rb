class CreateGuaraJobsSalaryRequirements < ActiveRecord::Migration
  def change
    create_table :guara_jobs_salary_requirements do |t|
      t.string :salary_range

      t.timestamps
    end
  end
end