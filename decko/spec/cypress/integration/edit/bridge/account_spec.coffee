describe 'account tab', () ->
  before ->
    cy.login("sample@user.com", "sample_pass")

  beforeEach ->
    cy.visit_bridge("Sample User")

  specify.only 'change email', () ->
    cy.bridge_sidebar().get('.nav-tabs a:first').click()
    cy.el("detail-pill").click()
    cy.get(".SELF-sample_user-Xaccount-Xemail.editable-view a.edit-link").click()
    cy.get("input.d0-card-content").clear().type("sam@user.com{enter}")
    cy.get(".SELF-sample_user-Xaccount-Xemail.editable-view")
      .should("contain", "sam@user.com")

    # edit back
    cy.get(".SELF-sample_user-Xaccount-Xemail.editable-view a.edit-link").click()
    cy.get("input.d0-card-content").clear().type("sample@user.com{enter}")

