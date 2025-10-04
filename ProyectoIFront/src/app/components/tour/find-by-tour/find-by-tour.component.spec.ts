import { ComponentFixture, TestBed } from '@angular/core/testing';

import { FindByTourComponent } from './find-by-tour.component';

describe('FindByTourComponent', () => {
  let component: FindByTourComponent;
  let fixture: ComponentFixture<FindByTourComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [FindByTourComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(FindByTourComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
